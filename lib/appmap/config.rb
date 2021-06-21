# frozen_string_literal: true

require 'yaml'
require 'appmap/handler/net_http'
require 'appmap/handler/rails/template'
require 'appmap/swagger/configuration'
require 'appmap/depends/configuration'

module AppMap
  class Config
    # Specifies a code +path+ to be mapped.
    # Options:
    #
    # * +gem+ may indicate a gem name that "owns" the path
    # * +package_name+ can be used to make sure that the code is required so that it can be loaded. This is generally used with
    #   builtins, or when the path to be required is not automatically required when bundler requires the gem.
    # * +exclude+ can be used used to exclude sub-paths. Generally not used with +gem+.
    # * +labels+ is used to apply labels to matching code. This is really only useful when the package will be applied to
    #   specific functions, via TargetMethods.
    # * +shallow+ indicates shallow mapping, in which only the entrypoint to a gem is recorded.
    Package = Struct.new(:path, :gem, :package_name, :exclude, :labels, :shallow) do
      # This is for internal use only.
      private_methods :gem

      # Specifies the class that will convert code events into event objects.
      attr_writer :handler_class

      def handler_class
        require 'appmap/handler/function'
        @handler_class || AppMap::Handler::Function
      end

      # Indicates that only the entry points to a package will be recorded.
      # Once the code has entered a package, subsequent calls within the package will not be
      # recorded unless the code leaves the package and re-enters it.
      def shallow?
        shallow
      end

      class << self
        # Builds a package for a path, such as `app/models` in a Rails app. Generally corresponds to a `path:` entry
        # in appmap.yml. Also used for mapping specific methods via TargetMethods.
        def build_from_path(path, shallow: false, package_name: nil, exclude: [], labels: [])
          Package.new(path, nil, package_name, exclude, labels, shallow)
        end

        # Builds a package for gem. Generally corresponds to a `gem:` entry in appmap.yml. Also used when mapping
        # a builtin.
        def build_from_gem(gem, shallow: true, package_name: nil, exclude: [], labels: [], optional: false, force: false)
          if !force && %w[method_source activesupport].member?(gem)
            warn "WARNING: #{gem} cannot be AppMapped because it is a dependency of the appmap gem"
            return
          end
          path = gem_path(gem, optional)
          if path
            Package.new(path, gem, package_name, exclude, labels, shallow)
          else
            warn "#{gem} is not available in the bundle" if AppMap::Hook::LOG
          end
        end

        private_class_method :new

        protected

        def gem_path(gem, optional)
          gemspec = Gem.loaded_specs[gem]
          # This exception will notify a user that their appmap.yml contains non-existent gems.
          raise "Gem #{gem.inspect} not found" unless gemspec || optional
          gemspec ? gemspec.gem_dir : nil
        end
      end

      def name
        gem || path
      end

      def to_h
        {
          path: path,
          package_name: package_name,
          gem: gem,
          handler_class: handler_class.name,
          exclude: Util.blank?(exclude) ? nil : exclude,
          labels: Util.blank?(labels) ? nil : labels,
          shallow: shallow
        }.compact
      end
    end

    # Identifies specific methods within a package which should be hooked.
    class TargetMethods # :nodoc:
      attr_reader :method_names, :package

      def initialize(method_names, package)
        @method_names = method_names
        @package = package
      end

      def include_method?(method_name)
        Array(method_names).include?(method_name)
      end

      def to_h
        {
          package: package.name,
          method_names: method_names
        }
      end
    end
    private_constant :TargetMethods

    # Function represents a specific function configured for hooking by the +functions+
    # entry in appmap.yml. When the Config is initialized, each Function is converted into
    # a Package and TargetMethods. It's called a Function rather than a Method, because Function
    # is the AppMap terminology.
    Function = Struct.new(:package, :cls, :labels, :function_names) do # :nodoc:
      def to_h
        {
          package: package,
          class: cls,
          labels: labels,
          functions: function_names.map(&:to_sym)
        }.compact
      end
    end
    private_constant :Function

    ClassTargetMethods = Struct.new(:cls, :target_methods) # :nodoc:
    private_constant :ClassTargetMethods

    MethodHook = Struct.new(:cls, :method_names, :labels) # :nodoc:
    private_constant :MethodHook
    
    class << self
      def package_hooks(gem_name, methods, handler_class: nil, package_name: nil)
        Array(methods).map do |method|
          package = Package.build_from_gem(gem_name, package_name: package_name, labels: method.labels, shallow: false, optional: true)
          next unless package

          package.handler_class = handler_class if handler_class
          ClassTargetMethods.new(method.cls, TargetMethods.new(Array(method.method_names), package))
        end.compact
      end

      def method_hook(cls, method_names, labels)
        MethodHook.new(cls, method_names, labels)
      end
    end

    # Hook well-known functions. When a function configured here is available in the bundle, it will be hooked with the
    # predefined labels specified here. If any of these hooks are not desired, they can be disabled in the +exclude+ section
    # of appmap.yml.
    METHOD_HOOKS = [
      package_hooks('actionview',
        [
          method_hook('ActionView::Renderer', :render, %w[mvc.view]),
          method_hook('ActionView::TemplateRenderer', :render, %w[mvc.view]),
          method_hook('ActionView::PartialRenderer', :render, %w[mvc.view])
        ],
        handler_class: AppMap::Handler::Rails::Template::RenderHandler,
        package_name: 'action_view'
      ),
      package_hooks('actionview',
        [
          method_hook('ActionView::Resolver', %i[find_all find_all_anywhere], %w[mvc.template.resolver])
        ],
        handler_class: AppMap::Handler::Rails::Template::ResolverHandler,
        package_name: 'action_view'
      ),
      package_hooks('actionpack',
        [
          method_hook('ActionDispatch::Request::Session', %i[[] dig values fetch], %w[http.session.read]),
          method_hook('ActionDispatch::Request::Session', %i[destroy[]= clear update delete merge], %w[http.session.write]),
          method_hook('ActionDispatch::Cookies::CookieJar', %i[[]= clear update delete recycle], %w[http.session.read]),
          method_hook('ActionDispatch::Cookies::CookieJar', %i[[]= clear update delete recycle], %w[http.session.write]),
          method_hook('ActionDispatch::Cookies::EncryptedCookieJar', %i[[]= clear update delete recycle], %w[http.cookie crypto.encrypt])
        ],
        package_name: 'action_dispatch'
      ),
      package_hooks('cancancan',
        [
          method_hook('CanCan::ControllerAdditions', %i[authorize! can? cannot?], %w[security.authorization]),
          method_hook('CanCan::Ability', %i[authorize?], %w[security.authorization])
        ]
      ),
      package_hooks('actionpack',
        [
          method_hook('ActionController::Instrumentation', %i[process_action send_file send_data redirect_to], %w[mvc.controller])
        ],
        package_name: 'action_controller'
      )
    ].flatten.freeze

    OPENSSL_PACKAGES = ->(labels) { Package.build_from_path('openssl', package_name: 'openssl', labels: labels) }

    # Hook functions which are builtin to Ruby. Because they are builtins, they may be loaded before appmap.
    # Therefore, we can't rely on TracePoint to report the loading of this code.
    BUILTIN_HOOKS = {
      'OpenSSL::PKey::PKey' => TargetMethods.new(:sign, OPENSSL_PACKAGES.(%w[crypto.pkey])),
      'OpenSSL::X509::Request' => TargetMethods.new(%i[sign verify], OPENSSL_PACKAGES.(%w[crypto.x509])),
      'OpenSSL::PKCS5' => TargetMethods.new(%i[pbkdf2_hmac_sha1 pbkdf2_hmac], OPENSSL_PACKAGES.(%w[crypto.pkcs5])),
      'OpenSSL::Cipher' => [
        TargetMethods.new(%i[encrypt], OPENSSL_PACKAGES.(%w[crypto.encrypt])),
        TargetMethods.new(%i[decrypt], OPENSSL_PACKAGES.(%w[crypto.decrypt]))
      ],
      'ActiveSupport::Callbacks::CallbackSequence' => [
        TargetMethods.new(:invoke_before, Package.build_from_gem('activesupport', force: true, package_name: 'active_support', labels: %w[mvc.before_action])),
        TargetMethods.new(:invoke_after, Package.build_from_gem('activesupport', force: true, package_name: 'active_support', labels: %w[mvc.after_action])),
      ],
      'ActiveSupport::SecurityUtils' => TargetMethods.new(:secure_compare, Package.build_from_gem('activesupport', force: true, package_name: 'active_support/security_utils', labels: %w[crypto.secure_compare])),
      'OpenSSL::X509::Certificate' => TargetMethods.new(:sign, OPENSSL_PACKAGES.(%w[crypto.x509])),
      'Net::HTTP' => TargetMethods.new(:request, Package.build_from_path('net/http', package_name: 'net/http', labels: %w[protocol.http]).tap do |package|
        package.handler_class = AppMap::Handler::NetHTTP
      end),
      'Net::SMTP' => TargetMethods.new(:send, Package.build_from_path('net/smtp', package_name: 'net/smtp', labels: %w[protocol.email.smtp])),
      'Net::POP3' => TargetMethods.new(:mails, Package.build_from_path('net/pop3', package_name: 'net/pop', labels: %w[protocol.email.pop])),
      # This is happening: Method send_command not found on Net::IMAP
      # 'Net::IMAP' => TargetMethods.new(:send_command, Package.build_from_path('net/imap', package_name: 'net/imap', labels: %w[protocol.email.imap])),
      # 'Marshal' => TargetMethods.new(%i[dump load], Package.build_from_path('marshal', labels: %w[format.marshal])),
      'Psych' => [
        TargetMethods.new(%i[load load_stream parse parse_stream], Package.build_from_path('yaml', package_name: 'psych', labels: %w[format.yaml.parse])),
        TargetMethods.new(%i[dump dump_stream], Package.build_from_path('yaml', package_name: 'psych', labels: %w[format.yaml.generate])),
      ],
      'JSON::Ext::Parser' => TargetMethods.new(:parse, Package.build_from_path('json', package_name: 'json', labels: %w[format.json.parse])),
      'JSON::Ext::Generator::State' => TargetMethods.new(:generate, Package.build_from_path('json', package_name: 'json', labels: %w[format.json.generate])),
    }.freeze

    attr_reader :name, :appmap_dir, :packages, :exclude, :swagger_config, :depends_config, :hooked_methods, :builtin_hooks

    def initialize(name,
      packages: [],
      swagger_config: Swagger::Configuration.new,
      depends_config: Depends::Configuration.new,
      exclude: [],
      functions: [])
      @name = name
      @appmap_dir = AppMap::DEFAULT_APPMAP_DIR
      @packages = packages
      @swagger_config = swagger_config
      @depends_config = depends_config
      @hook_paths = Set.new(packages.map(&:path))
      @exclude = exclude
      @builtin_hooks = BUILTIN_HOOKS
      @functions = functions

      @hooked_methods = METHOD_HOOKS.each_with_object(Hash.new { |h,k| h[k] = [] }) do |cls_target_methods, hooked_methods|
        hooked_methods[cls_target_methods.cls] << cls_target_methods.target_methods
      end

      functions.each do |func|
        package_options = {}
        package_options[:labels] = func.labels if func.labels
        @hooked_methods[func.cls] << TargetMethods.new(func.function_names, Package.build_from_path(func.package, package_options))
      end

      @hooked_methods.each_value do |hooks|
        Array(hooks).each do |hook|
          @hook_paths << hook.package.path
        end
      end
    end

    class << self
      # Loads configuration data from a file, specified by the file name.
      def load_from_file(config_file_name)
        logo = lambda do
          Util.color(<<~LOGO, :magenta)
             ___             __  ___
            / _ | ___  ___  /  |/  /__ ____
           / __ |/ _ \\/ _ \\/ /|_/ / _ `/ _ \\
          /_/ |_/ .__/ .__/_/  /_/\\_,_/ .__/
               /_/  /_/              /_/
          LOGO
        end

        config_present = true if File.exists?(config_file_name)

        config_data = if config_present
          YAML.safe_load(::File.read(config_file_name))
        else
          warn logo.()
          warn ''
          warn Util.color(%Q|NOTICE: The AppMap config file #{config_file_name} was not found!|, :magenta, bold: true)
          warn ''
          warn Util.color(<<~MISSING_FILE_MSG, :magenta)
          AppMap uses this file to customize its behavior. For example, you can use
          the 'packages' setting to indicate which local file paths and dependency
          gems you want to include in the AppMap. Since you haven't provided specific
          settings, the appmap gem will try and guess some reasonable defaults.
          To suppress this message, create the file:
          
          #{Pathname.new(config_file_name).expand_path}.
          
          Here are the default settings that will be used in the meantime. You can
          copy and paste this example to start your appmap.yml.
          MISSING_FILE_MSG
          {}
        end
        load(config_data).tap do |config|
          config_yaml = {
            'name' => config.name,
            'packages' => config.packages.select{|p| p.path}.map do |pkg|
              { 'path' => pkg.path }
            end,
            'exclude' => []
          }.compact
          unless config_present
            warn Util.color(YAML.dump(config_yaml), :magenta)
            warn logo.()
          end
        end
      end

      # Loads configuration from a Hash.
      def load(config_data)
        name = config_data['name'] || guess_name
        config_params = {
          exclude: config_data['exclude']
        }.compact

        if config_data['functions']
          config_params[:functions] = config_data['functions'].map do |function_data|
            package = function_data['package']
            cls = function_data['class']
            functions = function_data['function'] || function_data['functions']
            raise %q(AppMap config 'function' element should specify 'package', 'class' and 'function' or 'functions') unless package && cls && functions

            functions = Array(functions).map(&:to_sym)
            labels = function_data['label'] || function_data['labels']
            labels = Array(labels).map(&:to_s) if labels
            Function.new(package, cls, labels, functions)
          end
        end

        config_params[:packages] = \
          if config_data['packages']
            config_data['packages'].map do |package|
              gem = package['gem']
              path = package['path']
              raise %q(AppMap config 'package' element should specify 'gem' or 'path', not both) if gem && path

              if gem
                shallow = package['shallow']
                # shallow is true by default for gems
                shallow = true if shallow.nil?
                Package.build_from_gem(gem, exclude: package['exclude'] || [], shallow: shallow)
              else
                Package.build_from_path(path, exclude: package['exclude'] || [], shallow: package['shallow'])
              end
            end.compact
          else
            Array(guess_paths).map do |path|
              Package.build_from_path(path)
            end
          end

        if config_data['swagger']
          swagger_config = Swagger::Configuration.load(config_data['swagger'])
          config_params[:swagger_config] = swagger_config
        end
        if config_data['depends']
          depends_config = Depends::Configuration.load(config_data['depends'])
          config_params[:depends_config] = depends_config
        end

        Config.new name, config_params
      end

      def guess_name
        reponame = lambda do
          next unless File.directory?('.git')

          repo_name = `git config --get remote.origin.url`.strip
          repo_name.split('/').last.split('.').first unless repo_name == ''
        end
        dirname = -> { Dir.pwd.split('/').last }

        reponame.() || dirname.()
      end

      def guess_paths
        if defined?(::Rails)
          %w[app/controllers app/models]
        elsif File.directory?('lib')
          %w[lib]
        end
      end
    end

    def to_h
      {
        name: name,
        packages: packages.map(&:to_h),
        functions: @functions.map(&:to_h),
        exclude: exclude
      }.compact
    end

    # Determines if methods defined in a file path should possibly be hooked.
    def path_enabled?(path)
      path = AppMap::Util.normalize_path(path)
      @hook_paths.find { |hook_path| path.index(hook_path) == 0 }
    end

    # Looks up a class and method in the config, to find the matching Package configuration.
    # This class is only used after +path_enabled?+ has returned `true`. 
    LookupPackage = Struct.new(:config, :cls, :method) do
      def package
        # Global "excludes" configuration can be used to ignore any class/method.
        return if config.never_hook?(cls, method)

        package_for_code_object || package_for_location
      end

      # Hook a method which is specified by class and method name.
      def package_for_code_object
        Array(config.hooked_methods[cls.name])
          .compact
          .find { |hook| hook.include_method?(method.name) }
          &.package
      end

      # Hook a method which is specified by code location (i.e. path).
      def package_for_location
        location = method.source_location
        location_file, = location
        return unless location_file

        location_file = AppMap::Util.normalize_path(location_file)
        config
          .packages
          .select { |pkg| pkg.path }
          .find do |pkg|
            (location_file.index(pkg.path) == 0) &&
              !pkg.exclude.find { |p| location_file.index(p) }
          end
      end
    end

    def lookup_package(cls, method)
      LookupPackage.new(self, cls, method).package
    end

    def never_hook?(cls, method)
      _, separator, = ::AppMap::Hook.qualify_method_name(method)
      return true if exclude.member?(cls.name) || exclude.member?([ cls.name, separator, method.name ].join)
    end
  end
end

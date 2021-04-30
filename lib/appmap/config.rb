# frozen_string_literal: true

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
          exclude: exclude.blank? ? nil : exclude,
          labels: labels.blank? ? nil : labels,
          shallow: shallow
        }.compact
      end
    end

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

    OPENSSL_PACKAGES = ->(labels) { Package.build_from_path('openssl', package_name: 'openssl', labels: labels) }

    # Methods that should always be hooked, with their containing
    # package and labels that should be applied to them.
    HOOKED_METHODS = {
      'ActionView::Renderer' => TargetMethods.new(:render, Package.build_from_gem('actionview', package_name: 'action_view', labels: %w[mvc.view], optional: true)),
      'ActionDispatch::Request::Session' => TargetMethods.new(%i[destroy [] dig values []= clear update delete fetch merge], Package.build_from_gem('actionpack', package_name: 'action_dispatch', labels: %w[http.session], optional: true)),
      'ActionDispatch::Cookies::CookieJar' => TargetMethods.new(%i[[]= clear update delete recycle], Package.build_from_gem('actionpack', package_name: 'action_dispatch', labels: %w[http.cookie], optional: true)),
      'ActionDispatch::Cookies::EncryptedCookieJar' => TargetMethods.new(%i[[]=], Package.build_from_gem('actionpack', package_name: 'action_dispatch', labels: %w[http.cookie crypto.encrypt], optional: true)),
      'CanCan::ControllerAdditions' => TargetMethods.new(%i[authorize! can? cannot?], Package.build_from_gem('cancancan', labels: %w[security.authorization], optional: true)),
      'CanCan::Ability' => TargetMethods.new(%i[authorize!], Package.build_from_gem('cancancan', labels: %w[security.authorization], optional: true)),
      'ActionController::Instrumentation' => [
        TargetMethods.new(%i[process_action send_file send_data redirect_to], Package.build_from_gem('actionpack', package_name: 'action_controller', labels: %w[mvc.controller], optional: true)),
        TargetMethods.new(%i[render], Package.build_from_gem('actionpack', package_name: 'action_controller', labels: %w[mvc.view], optional: true)),
      ]
    }.freeze

    BUILTIN_METHODS = {
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
      'Psych' => TargetMethods.new(%i[dump dump_stream load load_stream parse parse_stream], Package.build_from_path('yaml', package_name: 'psych', labels: %w[format.yaml])),
      'JSON::Ext::Parser' => TargetMethods.new(:parse, Package.build_from_path('json', package_name: 'json', labels: %w[format.json])),
      'JSON::Ext::Generator::State' => TargetMethods.new(:generate, Package.build_from_path('json', package_name: 'json', labels: %w[format.json])),
    }.freeze

    attr_reader :name, :packages, :exclude, :hooked_methods, :builtin_methods

    def initialize(name, packages, exclude: [], functions: [])
      @name = name
      @packages = packages
      @hook_paths = packages.map(&:path)
      @exclude = exclude
      @builtin_methods = BUILTIN_METHODS
      @functions = functions
      @hooked_methods = HOOKED_METHODS.dup
      functions.each do |func|
        package_options = {}
        package_options[:labels] = func.labels if func.labels
        @hooked_methods[func.cls] ||= []
        @hooked_methods[func.cls] << TargetMethods.new(func.function_names, Package.build_from_path(func.package, package_options))
      end

      @hooked_methods.each_value do |hooks|
        Array(hooks).each do |hook|
          @hook_paths << hook.package.path if hook.package
        end
      end
    end

    class << self
      # Loads configuration data from a file, specified by the file name.
      def load_from_file(config_file_name)
        require 'yaml'
        load YAML.safe_load(::File.read(config_file_name))
      end

      # Loads configuration from a Hash.
      def load(config_data)
        functions = (config_data['functions'] || []).map do |function_data|
          package = function_data['package']
          cls = function_data['class']
          functions = function_data['function'] || function_data['functions']
          raise 'AppMap class configuration should specify package, class and function(s)' unless package && cls && functions
          functions = Array(functions).map(&:to_sym)
          labels = function_data['label'] || function_data['labels']
          labels = Array(labels).map(&:to_s) if labels
          Function.new(package, cls, labels, functions)
        end
        packages = (config_data['packages'] || []).map do |package|
          gem = package['gem']
          path = package['path']
          raise 'AppMap package configuration should specify gem or path, not both' if gem && path

          if gem
            shallow = package['shallow']
            # shallow is true by default for gems
            shallow = true if shallow.nil?
            Package.build_from_gem(gem, exclude: package['exclude'] || [], shallow: shallow)
          else
            Package.build_from_path(path, exclude: package['exclude'] || [], shallow: package['shallow'])
          end
        end.compact
        exclude = config_data['exclude'] || []
        Config.new config_data['name'], packages, exclude: exclude, functions: functions
      end
    end

    def to_h
      {
        name: name,
        packages: packages.map(&:to_h),
        functions: @functions.map(&:to_h),
        exclude: exclude
      }
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

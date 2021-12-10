# frozen_string_literal: true

require 'pathname'
require 'set'
require 'yaml'
require 'appmap/util'
require 'appmap/handler/net_http'
require 'appmap/handler/rails/template'
require 'appmap/service/guesser'
require 'appmap/swagger/configuration'
require 'appmap/depends/configuration'

module AppMap
  class Config
    # Specifies a logical code package be mapped.
    # This can be a project source folder, a Gem, or a builtin.
    #
    # Options:
    #
    # * +path+ indicates a relative path to a code folder.
    # * +gem+ may indicate a gem name that "owns" the path
    # * +require_name+ can be used to make sure that the code is required so that it can be loaded. This is generally used with
    #   builtins, or when the path to be required is not automatically required when bundler requires the gem.
    # * +exclude+ can be used used to exclude sub-paths. Generally not used with +gem+.
    # * +labels+ is used to apply labels to matching code. This is really only useful when the package will be applied to
    #   specific functions, via TargetMethods.
    # * +shallow+ indicates shallow mapping, in which only the entrypoint to a gem is recorded.
    Package = Struct.new(:name, :path, :gem, :require_name, :exclude, :labels, :shallow, :builtin) do
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

      # Clones this package into a sub-package, if needed.
      # For example, suppose the appmap.yml specifies package `app/models`. If some code in
      # `app/models/dao/user.rb` is mapped, it will be associated with a sub-package
      # `app/models/dao`.
      def subpackage(location, config)
        return self if gem

        path = location.split('/')[0...-1].join('/')
        clone.tap do |pkg|
          pkg.name = path
          pkg.path = path
          config.packages << pkg
        end
      end

      class << self
        # Builds a package for a path, such as `app/models` in a Rails app. Generally corresponds to a `path:` entry
        # in appmap.yml. Also used for mapping specific methods via TargetMethods.
        def build_from_path(path, shallow: false, require_name: nil, exclude: [], labels: [])
          Package.new(path, path, nil, require_name, exclude, labels, shallow)
        end

        def build_from_builtin(path, shallow: false, require_name: nil, exclude: [], labels: [])
          Package.new(path, path, nil, require_name, exclude, labels, shallow, true)
        end

        # Builds a package for gem. Generally corresponds to a `gem:` entry in appmap.yml. Also used when mapping
        # a builtin.
        def build_from_gem(gem, shallow: true, require_name: nil, exclude: [], labels: [], optional: false, force: false)
          if !force && %w[method_source activesupport].member?(gem)
            warn "WARNING: #{gem} cannot be AppMapped because it is a dependency of the appmap gem"
            return
          end
          path = gem_path(gem, optional)
          if path
            Package.new(gem, path, gem, require_name, exclude, labels, shallow)
          else
            AppMap::Util.startup_message "#{gem} is not available in the bundle"
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

      def to_h
        {
          name: name,
          path: path,
          gem: gem,
          require_name: require_name,
          handler_class: handler_class ? handler_class.name : nil,
          exclude: Util.blank?(exclude) ? nil : exclude,
          labels: Util.blank?(labels) ? nil : labels,
          shallow: shallow.nil? ? nil : shallow,
        }.compact
      end
    end

    # Identifies specific methods within a package which should be hooked.
    class TargetMethods # :nodoc:
      attr_reader :method_names, :package

      def initialize(method_names, package)
        @method_names = Array(method_names).map(&:to_sym)
        @package = package
      end

      def include_method?(method_name)
        method_names.include?(method_name.to_sym)
      end

      def to_h
        {
          package: package.name,
          method_names: method_names
        }
      end

      alias as_json to_h
    end
    private_constant :TargetMethods

    # Function represents a specific function configured for hooking by the +functions+
    # entry in appmap.yml. When the Config is initialized, each Function is converted into
    # a Package and TargetMethods. It's called a Function rather than a Method, because Function
    # is the AppMap terminology.
    Function = Struct.new(:package, :cls, :labels, :function_names, :builtin, :require_name) do # :nodoc:
      def to_h
        {
          package: package,
          require_name: require_name,
          class: cls,
          labels: labels,
          functions: function_names.map(&:to_sym),
          builtin: builtin
        }.compact
      end
    end
    private_constant :Function

    ClassTargetMethods = Struct.new(:cls, :target_methods) # :nodoc:
    private_constant :ClassTargetMethods

    MethodHook = Struct.new(:cls, :method_names, :labels) # :nodoc:
    private_constant :MethodHook
    
    class << self
      def package_hooks(methods, path: nil, gem: nil, force: false, builtin: false, handler_class: nil, require_name: nil)
        Array(methods).map do |method|
          package = if builtin
            Package.build_from_builtin(path || require_name, require_name: require_name, labels: method.labels, shallow: false)
          elsif gem
            Package.build_from_gem(gem, require_name: require_name, labels: method.labels, shallow: false, force: force, optional: true)
          elsif path
            Package.build_from_path(path, require_name: require_name, labels: method.labels, shallow: false)
          end
          next unless package

          package.handler_class = handler_class if handler_class
          ClassTargetMethods.new(method.cls, TargetMethods.new(Array(method.method_names), package))
        end.compact
      end

      def method_hook(cls, method_names, labels)
        MethodHook.new(cls, method_names, labels)
      end

      def declare_hook(hook_decl)
        hook_decl = YAML.load(hook_decl) if hook_decl.is_a?(String)
        
        methods_decl = hook_decl['methods'] || hook_decl['method']
        methods_decl = Array(methods_decl) unless methods_decl.is_a?(Hash)
        labels_decl = Array(hook_decl['labels'] || hook_decl['label'])

        methods = methods_decl.map do |name|
          class_name, method_name, static = name.include?('.') ? name.split('.', 2) + [ true ] : name.split('#', 2) + [ false ]
          method_hook class_name, [ method_name ], labels_decl
        end

        require_name = hook_decl['require_name']
        gem_name = hook_decl['gem']
        path = hook_decl['path']
        builtin = hook_decl['builtin']

        options = {
          builtin: builtin,
          gem: gem_name,
          path: path,
          require_name: require_name || gem_name || path,
          force: hook_decl['force']
        }.compact

        handler_class = hook_decl['handler_class']
        options[:handler_class] = Util.class_from_string(handler_class) if handler_class
        
        package_hooks(methods, **options)
      end

      def declare_hook_deprecated(hook_decl)
        function_name = hook_decl['name']
        package, cls, functions = []
        if function_name
          package, cls, _, function = Util.parse_function_name(function_name)
          functions = Array(function)
        else
          package = hook_decl['package']
          cls = hook_decl['class']
          functions = hook_decl['function'] || hook_decl['functions']
          raise %q(AppMap config 'function' element should specify 'package', 'class' and 'function' or 'functions') unless package && cls && functions
        end

        functions = Array(functions).map(&:to_sym)
        labels = hook_decl['label'] || hook_decl['labels']
        req = hook_decl['require']
        builtin = hook_decl['builtin']

        package_options = {}
        package_options[:labels] = Array(labels).map(&:to_s) if labels
        package_options[:require_name] = req
        package_options[:require_name] ||= package if builtin
        tm = TargetMethods.new(functions, Package.build_from_path(package, **package_options))
        ClassTargetMethods.new(cls, tm)
      end

      def builtin_hooks_path
        [ [ __dir__, 'builtin_hooks' ].join('/') ] + ( ENV['APPMAP_BUILTIN_HOOKS_PATH'] || '').split(/[;:]/)
      end

      def gem_hooks_path
        [ [ __dir__, 'gem_hooks' ].join('/') ] + ( ENV['APPMAP_GEM_HOOKS_PATH'] || '').split(/[;:]/)
      end

      def load_hooks
        loader = lambda do |dir, &block|
          basename = dir.split('/').compact.join('/')
          [].tap do |hooks|
            Dir.glob(Pathname.new(dir).join('**').join('*.yml').to_s).each do |yaml_file|
              path = yaml_file[basename.length + 1...-4]
              YAML.load(File.read(yaml_file)).map do |config|
                block.call path, config
                config
              end.each do |config|
                hooks << declare_hook(config)
              end
            end
          end.compact
        end

        builtin_hooks = builtin_hooks_path.map do |path|
          loader.(path) do |path, config|
            config['path'] = path
            config['builtin'] = true
          end
        end

        gem_hooks = gem_hooks_path.map do |path|
          loader.(path) do |path, config|
            config['gem'] = path
            config['builtin'] = false
          end
        end

        (builtin_hooks + gem_hooks).flatten
      end
    end

    attr_reader :name, :appmap_dir, :packages, :exclude, :swagger_config, :depends_config, :gem_hooks, :builtin_hooks

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
      @functions = functions

      @builtin_hooks = Hash.new { |h,k| h[k] = [] }
      @gem_hooks = Hash.new { |h,k| h[k] = [] }
      
      (functions + self.class.load_hooks).each_with_object(Hash.new { |h,k| h[k] = [] }) do |cls_target_methods, gem_hooks|
        hooks = if cls_target_methods.target_methods.package.builtin
          @builtin_hooks
        else
          @gem_hooks
        end
        hooks[cls_target_methods.cls] << cls_target_methods.target_methods
      end

      @gem_hooks.each_value do |hooks|
        @hook_paths += Array(hooks).map { |hook| hook.package.path }.compact
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

        config_present = true if File.exist?(config_file_name)

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
          
          #{Pathname.new(config_file_name).expand_path}
          
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
        name = config_data['name'] || Service::Guesser.guess_name
        config_params = {
          exclude: config_data['exclude']
        }.compact

        if config_data['functions']
          config_params[:functions] = config_data['functions'].map do |hook_decl|
            if hook_decl['name'] || hook_decl['package']
              declare_hook_deprecated(hook_decl)
            else
              # Support the same syntax within the 'functions' that's used for externalized
              # hook config.
              declare_hook(hook_decl)
            end
          end.flatten
        end

        config_params[:packages] = \
          if config_data['packages']
            config_data['packages'].map do |package|
              gem = package['gem']
              path = package['path']
              raise %q(AppMap config 'package' element should specify 'gem' or 'path', not both) if gem && path
              raise %q(AppMap config 'package' element should specify 'gem' or 'path') unless gem || path

              if gem
                shallow = package['shallow']
                # shallow is true by default for gems
                shallow = true if shallow.nil?

                require_name = \
                  package['package'] || #deprecated
                  package['require_name']
                Package.build_from_gem(gem, require_name: require_name, exclude: package['exclude'] || [], shallow: shallow)
              else
                Package.build_from_path(path, exclude: package['exclude'] || [], shallow: package['shallow'])
              end
            end.compact
          else
            Array(Service::Guesser.guess_paths).map do |path|
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

        Config.new name, **config_params
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
        class_name = cls.to_s.index('#<Class:') == 0 ? cls.to_s['#<Class:'.length...-1] : cls.name
        Array(config.gem_hooks[class_name])
          .find { |hook| hook.include_method?(method.name) }
          &.package
      end

      # Hook a method which is specified by code location (i.e. path).
      def package_for_location
        location = method.source_location
        location_file, = location
        return unless location_file

        location_file = AppMap::Util.normalize_path(location_file)

        pkg = config
              .packages
              .select { |pkg| pkg.path }
              .select do |pkg|
                (location_file.index(pkg.path) == 0) &&
                  !pkg.exclude.find { |p| location_file.index(p) }
              end
              .min { |a, b| b.path <=> a.path } # Longest matching package first

        pkg.subpackage(location_file, config) if pkg
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

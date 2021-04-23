# frozen_string_literal: true

module AppMap
  class Config
    Package = Struct.new(:path, :gem, :package_name, :exclude, :labels, :shallow) do
      # Indicates that only the entry points to a package will be recorded.
      # Once the code has entered a package, subsequent calls within the package will not be
      # recorded unless the code leaves the package and re-enters it.
      def shallow?
        shallow
      end

      class << self
        def build_from_path(path, shallow: false, package_name: nil, exclude: [], labels: [])
          Package.new(path, nil, package_name, exclude, labels, shallow)
        end

        def build_from_gem(gem, shallow: true, package_name: nil, exclude: [], labels: [])
          if %w[method_source activesupport].member?(gem)
            warn "WARNING: #{gem} cannot be AppMapped because it is a dependency of the appmap gem"
            return
          end
          Package.new(gem_path(gem), gem, package_name, exclude, labels, shallow)
        end

        private_class_method :new

        protected

        def gem_path(gem)
          gemspec = Gem.loaded_specs[gem] or raise "Gem #{gem.inspect} not found"
          gemspec.gem_dir
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
          exclude: exclude.blank? ? nil : exclude,
          labels: labels.blank? ? nil : labels,
          shallow: shallow
        }.compact
      end
    end

    class Hook
      attr_reader :method_names, :package

      def initialize(method_names, package)
        @method_names = method_names
        @package = package
      end
    end

    OPENSSL_PACKAGES = ->(labels) { Package.build_from_path('openssl', package_name: 'openssl', labels: labels) }

    # Methods that should always be hooked, with their containing
    # package and labels that should be applied to them.
    HOOKED_METHODS = {
      'ActiveSupport::SecurityUtils' => Hook.new(:secure_compare, Package.build_from_path('active_support', labels: %w[crypto.secure_compare])),
      'ActionView::Renderer' => Hook.new(:render, Package.build_from_path('action_view', labels: %w[mvc.view])),
      'ActionDispatch::Request::Session' => Hook.new(%i[destroy [] dig values []= clear update delete fetch merge], Package.build_from_path('action_pack', labels: %w[http.session])),
      'ActionDispatch::Cookies::CookieJar' => Hook.new(%i[[]= clear update delete recycle], Package.build_from_path('action_pack', labels: %w[http.cookie])),
      'ActionDispatch::Cookies::EncryptedCookieJar' => Hook.new(%i[[]=], Package.build_from_path('action_pack', labels: %w[http.cookie crypto.encrypt])),
      'CanCan::ControllerAdditions' => Hook.new(%i[authorize! can? cannot?], Package.build_from_path('cancancan', labels: %w[security.authorization])),
      'CanCan::Ability' => Hook.new(%i[authorize!], Package.build_from_path('cancancan', labels: %w[security.authorization])),
      'ActionController::Instrumentation' => [
        Hook.new(%i[process_action send_file send_data redirect_to], Package.build_from_path('action_view', labels: %w[mvc.controller])),
        Hook.new(%i[render], Package.build_from_path('action_view', labels: %w[mvc.view])),
      ]
    }

    BUILTIN_METHODS = {
      'OpenSSL::PKey::PKey' => Hook.new(:sign, OPENSSL_PACKAGES.(%w[crypto.pkey])),
      'OpenSSL::X509::Request' => Hook.new(%i[sign verify], OPENSSL_PACKAGES.(%w[crypto.x509])),
      'OpenSSL::PKCS5' => Hook.new(%i[pbkdf2_hmac_sha1 pbkdf2_hmac], OPENSSL_PACKAGES.(%w[crypto.pkcs5])),
      'OpenSSL::Cipher' => [
        Hook.new(%i[encrypt], OPENSSL_PACKAGES.(%w[crypto.encrypt])),
        Hook.new(%i[decrypt], OPENSSL_PACKAGES.(%w[crypto.decrypt]))
      ],
      'OpenSSL::X509::Certificate' => Hook.new(:sign, OPENSSL_PACKAGES.(%w[crypto.x509])),
      'Net::HTTP' => Hook.new(:request, Package.build_from_path('net/http', package_name: 'net/http', labels: %w[protocol.http])),
      'Net::SMTP' => Hook.new(:send, Package.build_from_path('net/smtp', package_name: 'net/smtp', labels: %w[protocol.email.smtp])),
      'Net::POP3' => Hook.new(:mails, Package.build_from_path('net/pop3', package_name: 'net/pop', labels: %w[protocol.email.pop])),
      'Net::IMAP' => Hook.new(:send_command, Package.build_from_path('net/imap', package_name: 'net/imap', labels: %w[protocol.email.imap])),
      'Marshal' => Hook.new(%i[dump load], Package.build_from_path('marshal', labels: %w[format.marshal])),
      'Psych' => Hook.new(%i[dump dump_stream load load_stream parse parse_stream], Package.build_from_path('yaml', package_name: 'psych', labels: %w[format.yaml])),
      'JSON::Ext::Parser' => Hook.new(:parse, Package.build_from_path('json', package_name: 'json', labels: %w[format.json])),
      'JSON::Ext::Generator::State' => Hook.new(:generate, Package.build_from_path('json', package_name: 'json', labels: %w[format.json])),
    }.freeze

    attr_reader :name, :packages, :exclude

    def initialize(name, packages = [], exclude = [])
      @name = name
      @packages = packages
      @exclude = exclude
    end

    class << self
      # Loads configuration data from a file, specified by the file name.
      def load_from_file(config_file_name)
        require 'yaml'
        load YAML.safe_load(::File.read(config_file_name))
      end

      # Loads configuration from a Hash.
      def load(config_data)
        (config_data['classes'] || []).map do |cls|
          package = cls['package']
          name = cls['name']
          functions = cls['function'] || cls['functions']
          raise 'AppMap class configuration should specify package, name and function(s)' unless package && name && functions
          functions = Array(functions).map(&:to_sym)
          labels = cls['label'] || cls['labels']
          labels = Array(labels).map(&:to_s) if labels
          HOOKED_METHODS[name] ||= []
          class_hooks = HOOKED_METHODS[name]
          package_options = {}
          package_options[:labels] = labels if labels
          class_hooks << Hook.new(functions, Package.build_from_path(package, package_options))
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
        Config.new config_data['name'], packages, config_data['exclude'] || []
      end
    end

    def to_h
      {
        name: name,
        packages: packages.map(&:to_h),
        exclude: exclude
      }
    end

    # package_for_method finds the Package, if any, which configures the hook
    # for a method.
    def package_for_method(method)
      package_hooked_by_class(method) || package_hooked_by_source_location(method)
    end

    def package_hooked_by_class(method)
      defined_class, _, method_name = ::AppMap::Hook.qualify_method_name(method)
      return find_package(defined_class, method_name)
    end

    def package_hooked_by_source_location(method)
      location = method.source_location
      location_file, = location
      return unless location_file

      location_file = location_file[Dir.pwd.length + 1..-1] if location_file.index(Dir.pwd) == 0
      packages.select { |pkg| pkg.path }.find do |pkg|
        (location_file.index(pkg.path) == 0) &&
          !pkg.exclude.find { |p| location_file.index(p) }
      end
    end

    def never_hook?(method)
      defined_class, separator, method_name = ::AppMap::Hook.qualify_method_name(method)
      return true if exclude.member?(defined_class) || exclude.member?([ defined_class, separator, method_name ].join)
    end

    # always_hook? indicates a method that should always be hooked.
    def always_hook?(defined_class, method_name)
      !!find_package(defined_class, method_name)
    end

    # included_by_location? indicates a method whose source location matches a method definition that has been
    # configured for inclusion.
    def included_by_location?(method)
      !!package_for_method(method)
    end

    def find_package(defined_class, method_name)
      hooks = find_hooks(defined_class)
      return nil unless hooks

      hook = Array(hooks).find do |hook|
        Array(hook.method_names).include?(method_name)
      end
      hook ? hook.package : nil
    end

    def find_hooks(defined_class)
      Array(HOOKED_METHODS[defined_class] || BUILTIN_METHODS[defined_class])
    end
  end
end

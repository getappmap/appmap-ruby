# frozen_string_literal: true

module AppMap
  Package = Struct.new(:path, :package_name, :exclude, :labels) do
    def initialize(path, package_name, exclude, labels = nil)
      super
    end

    def to_h
      {
        path: path,
        package_name: package_name,
        exclude: exclude.blank? ? nil : exclude,
        labels: labels.blank? ? nil : labels
      }.compact
    end
  end

  class Config
    OPENSSL_PACKAGE = Package.new('openssl', 'openssl', nil, ['security'])

    # Methods that should always be hooked, with their containing
    # package and labels that should be applied to them.
    HOOKED_METHODS = {
      'ActiveSupport::SecurityUtils' => {
        secure_compare: Package.new('active_support', nil, nil, ['security'])
      }
    }

    BUILTIN_METHODS = {
      'OpenSSL::PKey::PKey' => {
        sign: OPENSSL_PACKAGE
      },
      'Digest::Instance' => {
        digest: OPENSSL_PACKAGE
      },
      'OpenSSL::X509::Request' => {
        sign: OPENSSL_PACKAGE,
        verify: OPENSSL_PACKAGE
      },
      'OpenSSL::PKCS5' => {
        pbkdf2_hmac_sha1: OPENSSL_PACKAGE,
        pbkdf2_hmac: OPENSSL_PACKAGE
      },
      'OpenSSL::Cipher' => {
        encrypt: OPENSSL_PACKAGE,
        decrypt: OPENSSL_PACKAGE,
        final: OPENSSL_PACKAGE
      },
      'OpenSSL::X509::Certificate' => {
        sign: Package.new('openssl', nil, nil, ['security'])
      },
      'Net::HTTP' => {
        request: Package.new('net/http', 'net/http', nil, %w[http io])
      },
      'Net::SMTP' => {
        send: Package.new('net/smtp', 'net/smtp', nil, %w[smtp email io])
      },
      'Net::POP3' => {
        mails: Package.new('net/pop3', 'net/pop', nil, %w[pop pop3 email io])
      },
      'Net::IMAP' => {
        send_command: Package.new('net/imap', 'net/imap', nil, %w[imap email io])
      },
      'IO' => {
        read: Package.new('io', nil, nil, %w[io]),
        write: Package.new('io', nil, nil, %w[io]),
        open: Package.new('io', nil, nil, %w[io]),
        close: Package.new('io', nil, nil, %w[io])
      }
    }

    attr_reader :name, :packages
    def initialize(name, packages = [])
      @name = name
      @packages = packages
    end

    class << self
      # Loads configuration data from a file, specified by the file name.
      def load_from_file(config_file_name)
        require 'yaml'
        load YAML.safe_load(::File.read(config_file_name))
      end

      # Loads configuration from a Hash.
      def load(config_data)
        packages = (config_data['packages'] || []).map do |package|
          Package.new(package['path'], nil, package['exclude'] || [])
        end
        Config.new config_data['name'], packages
      end
    end

    def to_h
      {
        name: name,
        packages: packages.map(&:to_h)
      }
    end

    def package_for_method(method)
      defined_class, _, method_name = Hook.qualify_method_name(method)
      hooked_method = find_hooked_method(defined_class, method_name)
      return hooked_method if hooked_method

      location = method.source_location
      location_file, = location
      return unless location_file

      location_file = location_file[Dir.pwd.length + 1..-1] if location_file.index(Dir.pwd) == 0
      packages.find do |pkg|
        (location_file.index(pkg.path) == 0) &&
          !pkg.exclude.find { |p| location_file.index(p) }
      end
    end

    def included_by_location?(method)
      !!package_for_method(method)
    end

    def always_hook?(defined_class, method_name)
      !!find_hooked_method(defined_class, method_name)
    end

    def find_hooked_method(defined_class, method_name)
      find_hooked_class(defined_class)[method_name]
    end

    def find_hooked_class(defined_class)
      HOOKED_METHODS[defined_class] || BUILTIN_METHODS[defined_class] || {}
    end
  end
end

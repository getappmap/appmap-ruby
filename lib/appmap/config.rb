# frozen_string_literal: true

module AppMap
  Package = Struct.new(:path, :exclude, :labels) do
    def initialize(path, exclude, labels = nil)
      super
    end
    
    def to_h
      {
        path: path,
        exclude: exclude.blank? ? nil : exclude,
        labels: labels.blank? ? nil : labels
      }.compact
    end
  end

  class Config
    # Methods that should always be hooked, with their containing
    # package and labels that should be applied to them.
    HOOKED_METHODS = {
      'ActiveSupport::SecurityUtils' => {
        secure_compare: Package.new('active_support', nil, ['security'])
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
          Package.new(package['path'], package['exclude'] || [])
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
      location = method.source_location
      location_file, = location
      return unless location_file

      defined_class,_,method_name = Hook.qualify_method_name(method)
      hooked_method = find_hooked_method(defined_class, method_name)
      return hooked_method if hooked_method
      
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
      HOOKED_METHODS[defined_class] || {}
    end
  end
end

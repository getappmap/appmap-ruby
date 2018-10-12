require 'appmap/config/path'
require 'appmap/config/file'
require 'appmap/config/directory'
require 'appmap/config/module_dir'
require 'appmap/config/rails'

module AppMap
  module Config
    class << self
      # Loads configuration data from a file, specified by the file name.
      def load_from_file(config_file_name)
        require 'yaml'
        config_data = Array(YAML.safe_load(::File.read(config_file_name)))
        config_data.map do |path, data|
          type = data.delete('type')
          case type
          when 'module'
            AppMap::Config::ModuleDir.new(path, data['name'] || path.split('/')[-1], exclude: data['exclude'])
          when 'directory'
            AppMap::Config::Directory.new(path)
          when 'file'
            AppMap::Config::File.new(path)
          when 'rails'
            AppMap::Config::Rails.new(path)
          else
            raise "Unknown config type #{type.inspect}"
          end
        end
      end
    end
  end
end

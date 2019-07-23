require 'appmap/config/path'
require 'appmap/config/file'
require 'appmap/config/directory'
require 'appmap/config/package_dir'
require 'appmap/config/dependency'

module AppMap
  module Config
    class Configuration
      attr_reader :name, :packages, :files, :dependencies

      def initialize(name)
        @name = name
        @packages = []
        @files = []
        @dependencies = []
      end

      def source_locations
        packages + files + dependencies
      end
    end

    class << self
      SPECIAL_DEPENDENCIES = [
        Config::Dependency.new(:rack_handler_webrick, 'rack', 'lib/rack/handler/webrick.rb',
                               %w[Rack Handler WEBrick], 'service', false)
      ].freeze

      # Loads configuration data from a file, specified by the file name.
      def load_from_file(config_file_name)
        require 'yaml'
        load YAML.safe_load(::File.read(config_file_name))
      end

      # Loads configuration from a Hash.
      def load(config_data)
        Configuration.new(config_data['name']).tap do |config|
          builders = Hash.new { |_, key| raise "Unknown config type #{key.inspect}" }
          builders[:packages] = lambda { |path, options|
            AppMap::Config::PackageDir.new(path).tap do |pdir|
              pdir.package_name = options['name'] if options['name']
              pdir.exclude = options['exclude'] if options['exclude']
            end
          }
          builders[:files] = ->(path, _) { AppMap::Config::File.new(path) }

          %i[packages files].each do |kind|
            next unless (members = config_data[kind.to_s])
            members.each do |member|
              path = member.delete('path')
              config.send(kind) << builders[kind].call(path, member)
            end
          end

          SPECIAL_DEPENDENCIES.each do |dep|
            config.dependencies << dep
          end
        end
      end
    end
  end
end

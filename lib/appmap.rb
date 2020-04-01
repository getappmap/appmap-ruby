# frozen_string_literal: true

begin
  require 'active_support'
  require 'active_support/core_ext'
rescue NameError
  warn 'active_support is not available. AppMap execution will continue optimistically without it...'
end

require 'appmap/version'

module AppMap
  BATCH_HEADER_NAME = 'AppLand-Scenario-Batch'

  class << self
    @config = nil
    @config_file_path = nil

    def configuration
      raise "AppMap is not configured" unless @config

      @config
    end

    def configure(config_file_path = 'appmap.yml')
      if @config
        return @config if @config_file_path == config_file_path

        raise "AppMap is already configured from #{@config_file_path}, can't reconfigure from #{config_file_path}"
      end

      warn "Configuring AppMap from path #{config_file_path}"
      require 'appmap/hook'
      AppMap::Hook::Config.load_from_file(config_file_path).tap do |config|
        @config = config
        @config_file_path = config_file_path
      end
    end

    # Simplified entry point to add hooks to code as it's loaded.
    def hook(config = configure)
      require 'appmap/hook'
      AppMap::Hook.hook(config)
    end
  end
end

require 'appmap/railtie' if defined?(::Rails::Railtie)

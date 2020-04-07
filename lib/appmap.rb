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

    # configuration gets the AppMap configuration.
    def configuration
      raise "AppMap is not configured" unless @config

      @config
    end

    # configure applies the configuration from a file. This method can only be performed once.
    # Be sure and call it before +hook+ if you want non-default configuration.
    #
    # Default behavior is to configure from "appmap.yml".
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

    # Activate the code hooks which record function calls as trace events.
    # Call this function before the program code is loaded by the Ruby VM, otherwise
    # the load events won't be seen and the hooks won't activate.
    def hook(config = configure)
      require 'appmap/hook'
      AppMap::Hook.hook(config)
    end

    # Access the AppMap::Tracers, which can be used to start tracing, stop tracing, and record events.
    def tracing
      require 'appmap/trace'
      @tracing ||= Trace::Tracers.new
    end

    # Build a class map from a config and a list of Ruby methods.
    def class_map(config, methods)
      require 'appmap/class_map'
      AppMap::ClassMap.build_from_methods(config, methods)
    end
  end
end

require 'appmap/railtie' if defined?(::Rails::Railtie)

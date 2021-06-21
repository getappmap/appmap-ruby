# frozen_string_literal: true

begin
  require 'active_support'
  require 'active_support/core_ext'
rescue NameError
  warn 'active_support is not available. AppMap execution will continue optimistically without it...'
end

require 'appmap/version'
require 'appmap/hook'
require 'appmap/config'
require 'appmap/trace'
require 'appmap/class_map'
require 'appmap/metadata'
require 'appmap/util'
require 'appmap/open'

# load extension
require 'appmap/appmap'

module AppMap
  class << self
    @configuration = nil
    @configuration_file_path = nil

    # Gets the configuration. If there is no configuration, the default
    # configuration is initialized.
    def configuration
      @configuration ||= initialize_configuration
    end

    # Sets the configuration. This is only expected to happen once per
    # Ruby process.
    def configuration=(config)
      warn 'AppMap is already configured' if @configuration && config

      @configuration = config
    end

    def default_config_file_path
      ENV['APPMAP_CONFIG_FILE'] || 'appmap.yml'
    end

    # Configures AppMap for recording. Default behavior is to configure from
    # APPMAP_CONFIG_FILE, or 'appmap.yml'. If no config file is available, a
    # configuration will be automatically generated and used - and the user is prompted
    # to create the config file.
    #
    # This method also activates the code hooks which record function calls as trace events.
    # Call this function before the program code is loaded by the Ruby VM, otherwise
    # the load events won't be seen and the hooks won't activate.
    def initialize_configuration(config_file_path = default_config_file_path)
      warn "Configuring AppMap from path #{config_file_path}"
      Config.load_from_file(config_file_path).tap do |configuration|
        self.configuration = configuration
        Hook.new(configuration).enable
      end
    end

    def info(msg)
      if defined?(::Rails) && defined?(::Rails.logger)
        ::Rails.logger.info msg
      else
        warn msg
      end
    end

    # Used to start tracing, stop tracing, and record events.
    def tracing
      @tracing ||= Trace::Tracing.new
    end

    # Records the events which occur while processing a block,
    # and returns an AppMap as a Hash.
    def record
      tracer = tracing.trace
      begin
        yield
      ensure
        tracing.delete(tracer)
      end

      events = [].tap do |event_list|
        event_list << tracer.next_event.to_h while tracer.event?
      end
      {
        'version' => AppMap::APPMAP_FORMAT_VERSION,
        'metadata' => detect_metadata,
        'classMap' => class_map(tracer.event_methods),
        'events' => events
      }
    end

    # Uploads an AppMap to the AppLand website and displays it.
    def open(appmap = nil, &block)
      appmap ||= AppMap.record(&block)
      AppMap::Open.new(appmap).perform
    end

    # Builds a class map from a config and a list of Ruby methods.
    def class_map(methods)
      ClassMap.build_from_methods(methods)
    end

    # Returns default metadata detected from the Ruby system and from the
    # filesystem.
    def detect_metadata
      @metadata ||= Metadata.detect.freeze
      @metadata.deep_dup
    end
  end
end

if Gem.loaded_specs['rails']
  require 'active_support'
  require 'active_support/core_ext'
  require 'rails'
  require 'appmap/railtie' 
end

if Gem.loaded_specs['rspec-core']
  require 'appmap/rspec'
end
  
if Gem.loaded_specs['minitest']
  require 'appmap/minitest'
end
  
AppMap.initialize_configuration if ENV['APPMAP'] == 'true'

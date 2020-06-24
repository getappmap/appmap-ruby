# frozen_string_literal: true

begin
  require 'active_support'
  require 'active_support/core_ext'
rescue NameError
  warn 'active_support is not available. AppMap execution will continue optimistically without it...'
end

require 'appmap/version'

module AppMap
  class << self
    @configuration = nil
    @configuration_file_path = nil

    # configuration gets the configuration. If there is no configuration, the default
    # configuration is initialized.
    def configuration
      @configuration ||= configure
    end

    # configuration= sets the configuration. This is only expected to happen once per
    # Ruby process.
    def configuration=(config)
      warn 'AppMap is already configured' if @configuration && config

      @configuration = config
    end

    # initialize configures AppMap for recording. Default behavior is to configure from "appmap.yml".
    # This method also activates the code hooks which record function calls as trace events.
    # Call this function before the program code is loaded by the Ruby VM, otherwise
    # the load events won't be seen and the hooks won't activate.
    def initialize(config_file_path = 'appmap.yml')
      warn "Configuring AppMap from path #{config_file_path}"
      require 'appmap/hook'
      self.configuration = Hook::Config.load_from_file(config_file_path)
      Hook.hook(configuration)
    end

    # tracing can be used to start tracing, stop tracing, and record events.
    def tracing
      require 'appmap/trace'
      @tracing ||= Trace::Tracing.new
    end

    # record records the events which occur while processing a block,
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

    # class_map builds a class map from a config and a list of Ruby methods.
    def class_map(methods)
      require 'appmap/class_map'
      ClassMap.build_from_methods(configuration, methods)
    end

    # detect_metadata returns default metadata detected from the Ruby system and from the
    # filesystem.
    def detect_metadata
      require 'appmap/metadata'
      @metadata ||= Metadata.detect.freeze
      @metadata.deep_dup
    end
  end
end

require 'appmap/railtie' if defined?(::Rails::Railtie)
AppMap.initialize unless ENV['APPMAP_INITIALIZE'] == 'false'

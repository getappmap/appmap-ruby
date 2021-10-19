# frozen_string_literal: true

require 'appmap/util'
require 'fileutils'
require 'active_support'
require 'active_support/core_ext'

module AppMap
  # Integration of AppMap with Minitest. When enabled with APPMAP=true, the AppMap tracer will
  # be activated around each test.
  module Minitest
    APPMAP_OUTPUT_DIR = 'tmp/appmap/minitest'
    LOG = ( ENV['APPMAP_DEBUG'] == 'true' || ENV['DEBUG'] == 'true' )

    def self.metadata
      AppMap.detect_metadata
    end

    Recording = Struct.new(:test, :test_name) do
      def initialize(test, test_name)
        super

        warn "Starting recording of test #{test.class}.#{test.name}@#{source_location}" if AppMap::Minitest::LOG
        @trace = AppMap.tracing.trace
      end

      def source_location
        test.method(test_name).source_location.join(':')
      end


      def finish(exception)
        warn "Finishing recording of test #{test.class}.#{test.name}" if AppMap::Minitest::LOG
        warn "Exception: #{exception}" if exception && AppMap::Minitest::LOG

        events = []
        AppMap.tracing.delete @trace

        events << @trace.next_event.to_h while @trace.event?

        AppMap::Minitest.add_event_methods @trace.event_methods

        class_map = AppMap.class_map(@trace.event_methods)

        feature_group = test.class.name.underscore.split('_')[0...-1].join('_').capitalize
        feature_name = test.name.split('_')[1..-1].join(' ')
        scenario_name = [ feature_group, feature_name ].join(' ')

        AppMap::Minitest.save name: scenario_name,
                              class_map: class_map,
                              source_location: source_location,
                              test_status: exception ? 'failed' : 'succeeded',
                              exception: exception,
                              events: events
      end
    end

    @recordings_by_test = {}
    @event_methods = Set.new
    @recording_count = 0

    class << self
      def init
        FileUtils.mkdir_p APPMAP_OUTPUT_DIR
      end

      def first_recording?
        @recording_count == 0
      end

      def begin_test(test, name)
        AppMap.info 'Configuring AppMap recorder for Minitest' if first_recording?
        @recording_count += 1

        @recordings_by_test[test.object_id] = Recording.new(test, name)
      end

      def end_test(test, exception:)
        recording = @recordings_by_test.delete(test.object_id)
        return warn "No recording found for #{test}" unless recording

        recording.finish exception
      end

      def config
        @config or raise "AppMap is not configured"
      end

      def add_event_methods(event_methods)
        @event_methods += event_methods
      end

      def save(name:, class_map:, source_location:, test_status:, exception:, events:)
        metadata = AppMap::Minitest.metadata.tap do |m|
          m[:name] = name
          m[:source_location] = source_location
          m[:app] = AppMap.configuration.name
          m[:frameworks] ||= []
          m[:frameworks] << {
            name: 'minitest',
            version: Gem.loaded_specs['minitest']&.version&.to_s
          }
          m[:recorder] = {
            name: 'minitest'
          }
          m[:test_status] = test_status
          if exception
            m[:exception] = {
              class: exception.class.name,
              message: AppMap::Event::MethodEvent.display_string(exception.to_s)
            }
          end
        end

        appmap = {
          version: AppMap::APPMAP_FORMAT_VERSION,
          metadata: metadata,
          classMap: class_map,
          events: events
        }.compact
        fname = AppMap::Util.scenario_filename(name)

        AppMap::Util.write_appmap(File.join(APPMAP_OUTPUT_DIR, fname), JSON.generate(appmap))
      end

      def enabled?
        ENV['APPMAP'] == 'true'
      end

      def run
        init
      end
    end
  end
end

if AppMap::Minitest.enabled?
  require 'appmap'
  require 'minitest/test'

  class ::Minitest::Test
    alias run_without_hook run

    def run
      GC.start
      AppMap::Minitest.begin_test self, name
      begin
        run_without_hook
      ensure
        AppMap::Minitest.end_test self, exception: $!
      end
    end
  end

  AppMap::Minitest.run
end

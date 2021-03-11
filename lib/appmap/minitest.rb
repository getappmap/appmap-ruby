# frozen_string_literal: true

require 'appmap/util'

module AppMap
  # Integration of AppMap with Minitest. When enabled with APPMAP=true, the AppMap tracer will
  # be activated around each test.
  module Minitest
    APPMAP_OUTPUT_DIR = 'tmp/appmap/minitest'
    LOG = false

    def self.metadata
      AppMap.detect_metadata
    end

    Recording = Struct.new(:test) do
      def initialize(test)
        super

        warn "Starting recording of test #{test.class}.#{test.name}" if AppMap::Minitest::LOG
        @trace = AppMap.tracing.trace
      end

      def finish
        warn "Finishing recording of test #{test.class}.#{test.name}" if AppMap::Minitest::LOG

        events = []
        AppMap.tracing.delete @trace

        events << @trace.next_event.to_h while @trace.event?

        AppMap::Minitest.add_event_methods @trace.event_methods

        class_map = AppMap.class_map(@trace.event_methods)

        feature_group = test.class.name.underscore.split('_')[0...-1].join('_').capitalize
        feature_name = test.name.split('_')[1..-1].join(' ')
        scenario_name = [ feature_group, feature_name ].join(' ')

        AppMap::Minitest.save scenario_name,
                              class_map,
                              events: events
      end
    end

    @recordings_by_test = {}
    @event_methods = Set.new

    class << self
      def init
        warn 'Configuring AppMap recorder for Minitest'

        FileUtils.mkdir_p APPMAP_OUTPUT_DIR
      end

      def begin_test(test)
        @recordings_by_test[test.object_id] = Recording.new(test)
      end

      def end_test(test)
        recording = @recordings_by_test.delete(test.object_id)
        return warn "No recording found for #{test}" unless recording

        recording.finish
      end

      def config
        @config or raise "AppMap is not configured"
      end

      def add_event_methods(event_methods)
        @event_methods += event_methods
      end

      def save(example_name, class_map, events: nil, labels: nil)
        metadata = AppMap::Minitest.metadata.tap do |m|
          m[:name] = example_name
          m[:app] = AppMap.configuration.name
          m[:frameworks] ||= []
          m[:frameworks] << {
            name: 'minitest',
            version: Gem.loaded_specs['minitest']&.version&.to_s
          }
          m[:recorder] = {
            name: 'minitest'
          }
        end

        appmap = {
          version: AppMap::APPMAP_FORMAT_VERSION,
          metadata: metadata,
          classMap: class_map,
          events: events
        }.compact
        fname = AppMap::Util.scenario_filename(example_name)

        File.write(File.join(APPMAP_OUTPUT_DIR, fname), JSON.generate(appmap))
      end

      def print_inventory
        class_map = AppMap.class_map(@event_methods)
        save 'Inventory', class_map, labels: %w[inventory]
      end

      def enabled?
        ENV['APPMAP'] == 'true'
      end

      def run
        init
        at_exit do
          print_inventory
        end
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
      AppMap::Minitest.begin_test self
      begin
        run_without_hook
      ensure
        AppMap::Minitest.end_test self
      end
    end
  end

  AppMap::Minitest.run
end

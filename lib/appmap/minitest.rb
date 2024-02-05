# frozen_string_literal: true

require_relative "../appmap"
require_relative "util"
require_relative "detect_enabled"
require "fileutils"
require "active_support"
require "active_support/core_ext"

module AppMap
  # Integration of AppMap with Minitest. When enabled with APPMAP=true, the AppMap tracer will
  # be activated around each test.
  module Minitest
    APPMAP_OUTPUT_DIR = File.join(AppMap.output_dir, "minitest")
    LOG = (ENV["APPMAP_DEBUG"] == "true" || ENV["DEBUG"] == "true")

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
        location = test.method(test_name).source_location
        [Util.normalize_path(location.first), location.last].join(":")
      end

      def finish(failures, exception)
        failed = failures.any? || exception
        if AppMap::Minitest::LOG
          warn "Finishing recording of #{failed ? "failed " : ""} test #{test.class}.#{test.name}"
        end
        warn "Exception: #{exception}" if exception && AppMap::Minitest::LOG

        if failed
          failure_exception = failures.first || exception
          warn "Failure exception: #{failure_exception}" if AppMap::Minitest::LOG
          test_failure = Util.extract_test_failure(failure_exception)
        end

        events = []
        AppMap.tracing.delete @trace

        events << @trace.next_event.to_h while @trace.event?

        AppMap::Minitest.add_event_methods @trace.event_methods

        class_map = AppMap.class_map(@trace.event_methods)

        feature_group = test.class.name.underscore.split("_")[0...-1].join("_").capitalize
        feature_name = test.name.split("_")[1..-1].join(" ")
        scenario_name = [feature_group, feature_name].join(" ")

        AppMap::Minitest.save name: scenario_name,
          class_map: class_map,
          source_location: source_location,
          test_status: failed ? "failed" : "succeeded",
          test_failure: test_failure,
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
        AppMap::DetectEnabled.discourage_conflicting_recording_methods :minitest if first_recording?

        @recording_count += 1

        recording = if defined?(::Minitest::Tagz) && disabled_by_tag(test, name)
            :disabled
          else
            Recording.new(test, name)
          end
        @recordings_by_test[test.object_id] = recording
      end

      def disabled_by_tag(test, name)
        tags = ::Minitest::Tagz.tag_map[::Minitest::Tagz.serialize(test.class, name)]
        tags && tags.include?("noappmap")
      end

      def end_test(test, exception:)
        recording = @recordings_by_test.delete(test.object_id)
        return warn "No recording found for #{test}" unless recording

        recording.finish test.failures || [], exception unless recording == :disabled
      end

      def config
        @config or raise "AppMap is not configured"
      end

      def add_event_methods(event_methods)
        @event_methods += event_methods
      end

      def save(name:, class_map:, source_location:, test_status:, test_failure:, exception:, events:)
        metadata = AppMap::Minitest.metadata.tap do |m|
          m[:name] = name
          m[:source_location] = source_location
          m[:app] = AppMap.configuration.name
          m[:frameworks] ||= []
          m[:frameworks] << {
            name: "minitest",
            version: Gem.loaded_specs["minitest"]&.version&.to_s
          }
          m[:recorder] = {
            name: "minitest",
            type: "tests"
          }
          m[:test_status] = test_status
          m[:test_failure] = test_failure if test_failure
          m[:exception] = Util.format_exception(exception) if exception
        end

        appmap = {
          version: AppMap::APPMAP_FORMAT_VERSION,
          metadata: metadata,
          classMap: class_map,
          events: events
        }.compact
        fname = AppMap::Util.scenario_filename(name)

        AppMap::Util.write_appmap(File.join(APPMAP_OUTPUT_DIR, fname), appmap)
      end

      def enabled?
        AppMap.recording_enabled?(:minitest)
      end

      def run
        init
      end
    end
  end
end

if AppMap::Minitest.enabled?
  require "appmap"
  require "minitest/test"

  class ::Minitest::Test
    alias_method :run_without_hook, :run

    def run
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

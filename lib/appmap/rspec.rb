# frozen_string_literal: true

require 'appmap/util'
require 'set'
require 'fileutils'

module AppMap
  # Integration of AppMap with RSpec. When enabled with APPMAP=true, the AppMap tracer will
  # be activated around each scenario which has the metadata key `:appmap`.
  module RSpec
    APPMAP_OUTPUT_DIR = 'tmp/appmap/rspec'
    LOG = false

    def self.metadata
      AppMap.detect_metadata
    end

    # ScopeExample and ScopeExampleGroup is a way to handle the weird way that RSpec
    # stores the nested example names.
    ScopeExample = Struct.new(:example) do
      alias_method :example_obj, :example

      def description?
        true
      end

      def description
        example.description
      end

      def parent
        ScopeExampleGroup.new(example.example_group)
      end
    end

    # As you can see here, the way that RSpec stores the example description and
    # represents the example group hierarchy is pretty weird.
    ScopeExampleGroup = Struct.new(:example_group) do
      alias_method :example_obj, :example_group

      def description_args
        # Don't stringify any hashes that RSpec considers part of the example group description.
        example_group.metadata[:description_args].reject { |arg| arg.is_a?(Hash) }
      end

      def description?
        return true if example_group.respond_to?(:described_class) && example_group.described_class

        return true if example_group.respond_to?(:description) && !description_args.empty?

        false
      end

      def description
        description? ? description_args.join(' ') : nil
      end

      def parent
        # An example group always has a parent; but it might be 'self'...

        # DEPRECATION WARNING: `Module#parent` has been renamed to `module_parent`. `parent` is deprecated and will be
        # removed in Rails 6.1. (called from parent at /Users/kgilpin/source/appland/appmap-ruby/lib/appmap/rspec.rb:110)
        example_group_parent = \
          if example_group.respond_to?(:module_parent)
            example_group.module_parent
          elsif example_group.respond_to?(:parent)
            example_group.parent
          elsif example_group.respond_to?(:parent_groups)
            example_group.parent_groups.first
          end

        example_group_parent != example_group ? ScopeExampleGroup.new(example_group_parent) : nil
      end
    end

    Recording = Struct.new(:example) do
      def initialize(example)
        super

        webdriver_port = lambda do
          return unless defined?(page) && page&.driver

          # This is the ugliest thing ever but I don't want to lose it.
          # All the WebDriver calls are getting app-mapped and it's really unclear
          # what they are.
          page.driver.options[:http_client].instance_variable_get('@server_url').port
        end

        warn "Starting recording of example #{example}@#{source_location}" if AppMap::RSpec::LOG
        GC.start
        @trace = AppMap.tracing.trace
        @webdriver_port = webdriver_port.()
      end

      def source_location
        result = example.location_rerun_argument.split(':')[0]
        result = result[2..-1] if result.index('./') == 0
        result
      end

      def finish(exception)
        warn "Finishing recording of example #{example}" if AppMap::RSpec::LOG
        warn "Exception: #{exception}" if exception && AppMap::RSpec::LOG

        events = []
        AppMap.tracing.delete @trace

        events << @trace.next_event.to_h while @trace.event?

        AppMap::RSpec.add_event_methods @trace.event_methods

        class_map = AppMap.class_map(@trace.event_methods)

        description = []
        scope = ScopeExample.new(example)
        while scope
          description << scope.description
          scope = scope.parent
        end

        description.reject!(&:nil?)
        description.reject!(&Util.method(:blank?))
        default_description = description.last
        description.reverse!

        normalize = lambda do |desc|
          desc.gsub('it should behave like', '')
              .gsub(/Controller$/, '')
              .gsub(/\s+/, ' ')
              .strip
        end

        full_description = normalize.call(description.join(' '))

        AppMap::RSpec.save name: full_description,
                           class_map: class_map,
                           source_location: source_location,
                           test_status: exception ? 'failed' : 'succeeded',
                           exception: exception,
                           events: events
      end
    end

    @recordings_by_example = {}
    @event_methods = Set.new
    @recording_count = 0

    class << self
      def init
        FileUtils.mkdir_p APPMAP_OUTPUT_DIR
      end

      def first_recording?
        @recording_count == 0
      end

      def begin_spec(example)
        AppMap.info 'Configuring AppMap recorder for RSpec' if first_recording?
        @recording_count += 1

        @recordings_by_example[example.object_id] = Recording.new(example)
      end

      def end_spec(example, exception:)
        recording = @recordings_by_example.delete(example.object_id)
        return warn "No recording found for #{example}" unless recording

        recording.finish exception
      end

      def config
        @config or raise "AppMap is not configured"
      end

      def add_event_methods(event_methods)
        @event_methods += event_methods
      end

      def save(name:, class_map:, source_location:, test_status:, exception:, events:)
        metadata = AppMap::RSpec.metadata.tap do |m|
          m[:name] = name
          m[:source_location] = source_location
          m[:app] = AppMap.configuration.name
          m[:frameworks] ||= []
          m[:frameworks] << {
            name: 'rspec',
            version: Gem.loaded_specs['rspec-core']&.version&.to_s
          }
          m[:recorder] = {
            name: 'rspec'
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

if AppMap::RSpec.enabled?
  require 'appmap'
  require 'active_support/inflector/transliterate'
  require 'rspec/core'
  require 'rspec/core/example'

  module RSpec
    module Core
      class Example
        class << self
          def wrap_example_block(example, fn)
            proc do
              AppMap::RSpec.begin_spec example
              begin
                instance_exec(&fn)
              ensure
                AppMap::RSpec.end_spec example, exception: $!
              end
            end
          end
        end

        def self.new(*arguments, &block)
          warn "Wrapping example_block for #{name}" if AppMap::RSpec::LOG
          allocate.tap do |obj|
            arguments[arguments.length - 1] = wrap_example_block(obj, arguments.last) if arguments.last.is_a?(Proc)
            obj.send :initialize, *arguments, &block
          end
        end
      end
    end
  end

  AppMap::RSpec.run
end

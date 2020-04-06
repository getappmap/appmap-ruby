# frozen_string_literal: true

module AppMap
  # Integration of AppMap with RSpec. When enabled with APPMAP=true, the AppMap tracer will
  # be activated around each scenario which has the metadata key `:appmap`.
  module RSpec
    APPMAP_OUTPUT_DIR = 'tmp/appmap/rspec'

    def self.metadata
      require 'appmap/command/record'
      @metadata ||= AppMap::Command::Record.detect_metadata
      @metadata.freeze
      @metadata.dup
    end

    class Recorder
      attr_reader :config

      def initialize(config)
        raise "Missing AppMap configuration setting: 'name'" unless config.name

        @config = config
      end

      def setup
        FileUtils.mkdir_p APPMAP_OUTPUT_DIR
      end

      def save(example_name, class_map, events: nil, feature_name: nil, feature_group_name: nil, labels: nil)
        metadata = RSpec.metadata.dup.tap do |m|
          m[:name] = example_name
          m[:app] = @config.name
          m[:feature] = feature_name if feature_name
          m[:feature_group] = feature_group_name if feature_group_name
          m[:labels] = labels if labels
          m[:frameworks] ||= []
          m[:frameworks] << {
            name: 'rspec',
            version: Gem.loaded_specs['rspec-core']&.version&.to_s
          }
          m[:recorder] = {
            name: 'rspec'
          }
        end

        appmap = {
          version: AppMap::APPMAP_FORMAT_VERSION,
          metadata: metadata,
          classMap: class_map,
          events: events
        }.compact
        fname = sanitize_filename(example_name)

        File.write(File.join(APPMAP_OUTPUT_DIR, "#{fname}.appmap.json"), JSON.generate(appmap))
      end

      # Cribbed from v5 version of ActiveSupport:Inflector#parameterize:
      # https://github.com/rails/rails/blob/v5.2.4/activesupport/lib/active_support/inflector/transliterate.rb#L92
      def sanitize_filename(fname, separator: '_')
        # Replace accented chars with their ASCII equivalents.
        fname = fname.encode('utf-8', invalid: :replace, undef: :replace, replace: '_')

        # Turn unwanted chars into the separator.
        fname.gsub!(/[^a-z0-9\-_]+/i, separator)

        re_sep = Regexp.escape(separator)
        re_duplicate_separator        = /#{re_sep}{2,}/
        re_leading_trailing_separator = /^#{re_sep}|#{re_sep}$/i

        # No more than one of the separator in a row.
        fname.gsub!(re_duplicate_separator, separator)

        # Finally, Remove leading/trailing separator.
        fname.gsub(re_leading_trailing_separator, '')
      end
    end

    class << self
      module FeatureAnnotations
        def feature
          return nil unless annotations

          annotations[:feature]
        end

        def labels
          labels = metadata[:appmap]
          if labels.is_a?(Array)
            labels
          elsif labels.is_a?(String) || labels.is_a?(Symbol)
            [ labels ]
          else
            []
          end
        end

        def feature_group
          return nil unless annotations

          annotations[:feature_group]
        end

        def annotations
          metadata.tap do |md|
            description_args_hashes.each do |h|
              md.merge! h
            end
          end
        end

        protected

        def metadata
          return {} unless example_obj.respond_to?(:metadata)

          example_obj.metadata
        end

        def description_args_hashes
          return [] unless example_obj.respond_to?(:metadata)

          (example_obj.metadata[:description_args] || []).select { |arg| arg.is_a?(Hash) }
        end
      end

      # ScopeExample and ScopeExampleGroup is a way to handle the weird way that RSpec
      # stores the nested example names.
      ScopeExample = Struct.new(:example) do
        include FeatureAnnotations

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
        include FeatureAnnotations

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
          example_group.parent != example_group ? ScopeExampleGroup.new(example_group.parent) : nil
        end
      end

      LOG = false

      def is_example_group_subclass_call?(tp)
        # Order is important here. Checking for method_id == :subclass
        # first will avoid calling defined_class.to_s in many cases,
        # some of which will fail.
        #
        # For example, ActiveRecord in Rails 4 defines #inspect (and
        # therefore #to_s) in such a way that it will fail if called
        # here.
        tp.event == :call &&
          tp.method_id == :subclass &&
          tp.defined_class.singleton_class? &&
          tp.defined_class.to_s == '#<Class:RSpec::Core::ExampleGroup>'
      end

      def is_example_initialize_call?(tp)
        tp.event == :call &&
          tp.method_id == :initialize &&
          tp.defined_class.to_s == 'RSpec::Core::Example'
      end

      def init
        warn 'Configuring AppMap recorder for RSpec'
        require 'appmap/hook'
        @config = AppMap.configure
        @event_methods = Set.new
        AppMap::Hook.hook(@config)
      end

      def generate_appmaps_from_specs
        recorder = Recorder.new(@config)
        recorder.setup

        require 'set'
        # file:lineno at which an Example block begins
        trace_block_start = Set.new
        # file:lineno at which an Example block ends
        trace_block_end = Set.new

        # value: a BlockParseNode from an RSpec file
        # key: file:lineno at which the block begins
        rspec_blocks = {}

        # value: an Example instance
        # key: file:lineno at which the Example block ends
        examples = {}

        current_tracer = nil

        TracePoint.trace(:call, :b_call, :b_return) do |tp|
          # When a new ExampleGroup is encountered, parse the source file containing it and look
          # for blocks that might be Examples. Index each BlockParseNode by the start file:lineno.
          if is_example_group_subclass_call?(tp)
            example_block = tp.binding.eval('example_group_block')
            source_path, start_line = example_block.source_location
            require 'appmap/rspec/parser'
            nodes, = AppMap::RSpec::Parser.new(file_path: source_path).parse
            nodes.each do |node|
              start_loc = [ node.file_path, node.first_line ].join(':')
              rspec_blocks[start_loc] = node
            end
          end

          # When a new Example is constructed with a block, look for the BlockParseNode that starts at the block's
          # file:lineno. If it exists, store the Example object, indexed by the file:lineno at which it ends.
          if is_example_initialize_call?(tp)
            example_block = tp.binding.eval('example_block')
            if example_block
              source_path, start_line = example_block.source_location
              start_loc = [ source_path, start_line ].join(':')
              if (rspec_block = rspec_blocks[start_loc])
                end_loc = [ source_path, rspec_block.last_line ].join(':')
                trace_block_start << start_loc.tap { |loc| puts "Start: #{loc}" if LOG }
                trace_block_end << end_loc.tap { |loc| puts "End: #{loc}" if LOG }
                examples[end_loc] = tp.binding.eval('self')
              end
            end
          end

          if %i[b_call b_return].member?(tp.event)
            loc = [ tp.path, tp.lineno ].join(':')
            puts loc if LOG && (trace_block_start.member?(loc) || trace_block_end.member?(loc))

            # When a new block is started, check if an Example block is known to begin at that
            # file:lineno. If it is, enable the AppMap tracer.
            if  tp.event == :b_call && trace_block_start.member?(loc)
              puts "Starting trace on #{loc}" if LOG

              current_tracer = AppMap.tracing.trace
            end

            # When the tracer is enabled and a block is completed, check to see if there is an
            # Example stored at the file:lineno. If so, finish tracing and emit the
            # AppMap file.
            if current_tracer && tp.event == :b_return && trace_block_end.member?(loc)
              puts "Ending trace on #{loc}" if LOG
              events = []
              AppMap.tracing.delete current_tracer

              while current_tracer.event?
                events << current_tracer.next_event.to_h
              end
              @event_methods += current_tracer.event_methods

              class_map = AppMap.class_map(@config, current_tracer.event_methods)

              example = examples[loc]
              description = []
              scope = ScopeExample.new(example)
              feature_group = feature = nil

              labels = []
              while scope
                labels += scope.labels
                description << scope.description
                feature ||= scope.feature
                feature_group ||= scope.feature_group
                scope = scope.parent
              end

              labels = labels.map(&:to_s).map(&:strip).reject(&:blank?).map(&:downcase).uniq
              description.reject!(&:nil?).reject(&:blank?)
              default_description = description.last
              description.reverse!

              normalize = lambda do |desc|
                desc.gsub('it should behave like', '')
                    .gsub(/Controller$/, '')
                    .gsub(/\s+/, ' ')
                    .strip
              end

              full_description = normalize.call(description.join(' '))

              compute_feature_name = lambda do
                return 'unknown' if description.empty?

                feature_description = description.dup
                num_tokens = [2, feature_description.length - 1].min
                feature_description[0...num_tokens].map(&:strip).join(' ')
              end

              feature_group ||= normalize.call(default_description).underscore.gsub('/', '_').humanize
              feature_name = feature || compute_feature_name.call if feature_group
              feature_name = normalize.call(feature_name) if feature_name

              recorder.save full_description,
                            class_map,
                            events: events,
                            feature_name: feature_name,
                            feature_group_name: feature_group,
                            labels: labels.blank? ? nil : labels
            end
          end
        end
      end

      def print_inventory
        recorder = Recorder.new(@config).tap(&:setup)
        class_map = AppMap.class_map(@config, @event_methods)
        recorder.save 'Inventory', class_map, labels: %w[inventory]
      end

      def enabled?
        ENV['APPMAP'] == 'true'
      end

      def run
        init
        generate_appmaps_from_specs
        at_exit do
          print_inventory
        end
      end
    end
  end
end

if AppMap::RSpec.enabled?
  require 'appmap'
  require 'active_support/inflector/transliterate'

  AppMap::RSpec.run
end


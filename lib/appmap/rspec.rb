# frozen_string_literal: true

require 'appmap'
require 'appmap/config'
require 'appmap/inspect'
require 'appmap/trace/tracer'

module AppMap
  # Integration of AppMap with RSpec. When enabled with APPMAP=true, the AppMap tracer will
  # be activated around each scenario which has the metadata key `:appmap`.
  module RSpec
    APPMAP_OUTPUT_DIR = 'tmp/appmap/rspec'

    class Recorder
      attr_reader :config, :features, :functions

      def initialize
        @config = AppMap::Config.load_from_file('appmap.yml')

        raise "Missing AppMap configuration setting: 'name'" unless @config.name

        @features = AppMap.inspect(@config)
        @functions = @features.map(&:collect_functions).flatten
      end

      def setup
        FileUtils.mkdir_p APPMAP_OUTPUT_DIR
      end

      # TODO: Optionally populate the 'layout' from appmap config or RSpec metadata.
      def save(example_name, events, feature_name: nil, feature_group_name: nil)
        require 'appmap/command/record'
        metadata = AppMap::Command::Record.detect_metadata.tap do |m|
          m[:name] = example_name
          m[:app] = @config.name
          m[:feature] = feature_name if feature_name
          m[:feature_group] = feature_group_name if feature_group_name
          m[:frameworks] ||= []
          m[:frameworks] << {
            name: 'rspec',
            version: Gem.loaded_specs['rspec-core']&.version&.to_s
          }
        end

        appmap = {
          version: '1.0',
          classMap: features,
          metadata: metadata,
          events: events
        }
        File.write(File.join(APPMAP_OUTPUT_DIR, "#{example_name}.json"), JSON.generate(appmap))
      end
    end

    class << self
      module FeatureAnnotations
        def feature
          return nil unless annotations

          annotations[:feature]
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

      def generate_appmaps_from_specs
        recorder = Recorder.new
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
          if tp.event == :call && tp.defined_class.to_s == '#<Class:RSpec::Core::ExampleGroup>' && tp.method_id == :subclass
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
          if tp.event == :call && tp.defined_class.to_s == 'RSpec::Core::Example' && tp.method_id == :initialize
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
              current_tracer = AppMap::Trace.tracers.trace(recorder.functions)
            end

            # When the tracer is enabled and a block is completed, check to see if there is an
            # Example stored at the file:lineno. If so, finish tracing and emit the 
            # AppMap file.
            if current_tracer && tp.event == :b_return && trace_block_end.member?(loc)
              puts "Ending trace on #{loc}" if LOG
              events = []
              AppMap::Trace.tracers.delete current_tracer

              while current_tracer.event?
                events << current_tracer.next_event.to_h
              end

              example = examples[loc]
              description = []
              scope = ScopeExample.new(example)
              feature_group = feature = nil
              while scope
                description << scope.description
                feature ||= scope.feature
                feature_group ||= scope.feature_group
                scope = scope.parent
              end
              description.reject! { |d| d.nil? || d == '' }
              description.reverse!

              description.each do |token|
                token = token.gsub 'it should behave like', ''
                token.gsub! '  ', ' '
                token.gsub! '/', '_'
                token.strip!
              end
              full_description = description.join(' ')

              recorder.save full_description, events,
                            feature_name: feature,
                            feature_group_name: feature_group
            end
          end
        end
      end
    end

    generate_appmaps_from_specs if ENV['APPMAP'] == 'true'
  end
end

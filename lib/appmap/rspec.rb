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

        features = config.source_locations.map(&AppMap::Inspect.method(:detect_features)).flatten
        @features = features.map(&:reparent)
        @features.each(&:prune)
        @functions = @features.map(&:collect_functions).flatten
      end

      def setup
        FileUtils.mkdir_p APPMAP_OUTPUT_DIR
      end

      def git_metadata
        git_repo = `git config --get remote.origin.url`.strip
        git_branch = `git rev-parse --abbrev-ref HEAD`.strip
        git_sha = `git rev-parse HEAD`.strip
        git_status = `git status -s`.split("\n").map(&:strip)
        git_last_annotated_tag = `git describe --abbrev=0 2>/dev/null`.strip
        git_last_annotated_tag = nil if git_last_annotated_tag.blank?
        git_last_tag = `git describe --abbrev=0 --tags 2>/dev/null`.strip
        git_last_tag = nil if git_last_tag.blank?
        git_commits_since_last_annotated_tag = `git describe`.strip =~ /-(\d+)-(\w+)$/[1] rescue 0 if git_last_annotated_tag
        git_commits_since_last_tag = `git describe --tags`.strip =~ /-(\d+)-(\w+)$/[1] rescue 0 if git_last_tag

        {
          repository: git_repo,
          branch: git_branch,
          commit: git_sha,
          status: git_status,
          git_last_annotated_tag: git_last_annotated_tag,
          git_last_tag: git_last_tag,
          git_commits_since_last_annotated_tag: git_commits_since_last_annotated_tag,
          git_commits_since_last_tag: git_commits_since_last_tag
        }
      end

      # TODO: Populate the 'layout' from appmap config or RSpec metadata
      def save(example_name, events, layout: nil)
        appmap = {
          version: '1.0',
          classMap: features,
          metadata: {
            name: example_name,
            app: @config.name,
          }.tap do |m|
            m[:layout] = layout if layout
            m[:git] = git_metadata if File.directory?('.git')
            m[:layout] = 'rails' if defined?(Rails)
          end,
          events: events
        }
        File.write(File.join(APPMAP_OUTPUT_DIR, "#{example_name}.json"), JSON.generate(appmap))
      end
    end

    class << self
      # ScopeExample and ScopeExampleGroup is a way to handle the weird way that RSpec
      # stores the nested example names.
      ScopeExample = Struct.new(:example) do
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

      def appmap_enabled?
        (defined?(::Rails) && ::Rails.application.config.appmap.enabled) ||
          (!defined?(::Rails) && ENV['APPMAP'] == 'true')
      end

      def generate_appmaps_from_specs
        recorder = Recorder.new
        recorder.setup

        ::RSpec.configure do |config|
          config.around(:example, :appmap) do |example|
            tracer = AppMap::Trace.tracer = AppMap::Trace::Tracer.new(recorder.functions)
            begin
              AppMap::Trace::Tracer.trace tracer

              example.run

              events = []
              while tracer.event?
                events << tracer.next_event.to_h
              end
            ensure
              AppMap::Trace.tracer = nil
            end

            description = []
            scope = ScopeExample.new(example)
            while scope
              description << scope.description
              scope = scope.parent
            end
            description.reject! { |d| d.nil? || d == '' }

            recorder.save description.reverse.map { |d| d.gsub('/', '_') }.join(' '), events
          end
        end
      end
    end

    generate_appmaps_from_specs if appmap_enabled?
  end
end

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

        features = config.source_locations.map(&AppMap::Inspect.method(:detect_features))
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
        git_commits_since_last_annotated_tag = `git describe`.strip =~ /-(\d+)-(\w+)$/[1] if git_last_annotated_tag
        git_commits_since_last_tag = `git describe --tags`.strip =~ /-(\d+)-(\w+)$/[1] if git_last_tag

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
      def appmap_enabled?
        ENV['APPMAP'] == 'true'
      end

      def generate_appmaps_from_specs
        recorder = Recorder.new
        recorder.setup

        ::RSpec.configure do |config|
          config.around(:example, :appmap) do |example|
            tracer = AppMap::Trace.tracer = AppMap::Trace::Tracer.new(recorder.functions)
            AppMap::Trace::Tracer.trace tracer

            example.run

            events = []
            while tracer.event?
              events << tracer.next_event.to_h
            end

            recorder.save example.full_description, events
          end
        end
      end
    end

    generate_appmaps_from_specs if appmap_enabled?
  end
end

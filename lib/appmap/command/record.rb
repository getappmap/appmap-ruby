# frozen_string_literal: true

module AppMap
  module Command
    RecordStruct = Struct.new(:config, :program)

    class Record < RecordStruct
      class << self
        # Builds a Hash of metadata which can be detected by inspecting the system.
        def detect_metadata
          {
            language: {
              name: 'ruby',
              engine: RUBY_ENGINE,
              version: RUBY_VERSION
            },
            client: {
              name: 'appmap',
              url: AppMap::URL,
              version: AppMap::VERSION
            }
          }.tap do |m|
            if defined?(::Rails)
              m[:frameworks] ||= []
              m[:frameworks] << {
                name: 'rails',
                version: ::Rails.version
              }
            end
            m[:git] = git_metadata if git_available
          end
        end

        protected

        def git_available
          @git_available = system('git status 2>&1 > /dev/null') if @git_available.nil?
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
      end

      def perform(&block)
        AppMap::Hook.hook(config)

        require 'appmap/trace/tracer'
        tracer = AppMap::Trace.tracers.trace

        events = []
        quit = false
        event_thread = Thread.new do
          while tracer.event? || !quit
            event = tracer.next_event
            if event
              events << event.to_h
            else
              sleep 0.0001
            end
          end
        end
        event_thread.abort_on_exception = true

        at_exit do
          quit = true
          event_thread.join
          yield AppMap::APPMAP_FORMAT_VERSION, detect_metadata, class_map, events
        end

        load program if program
      end
    end
  end
end

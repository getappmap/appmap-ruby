# frozen_string_literal: true

require "appmap/util"

module AppMap
  module Metadata
    class << self
      def detect
        {
          app: AppMap.configuration.name,
          language: {
            name: "ruby",
            engine: RUBY_ENGINE,
            version: RUBY_VERSION
          },
          client: {
            name: "appmap",
            url: AppMap::URL,
            version: AppMap::VERSION
          },
          timestamp: Time.now.to_f
        }.tap do |m|
          if defined?(::Rails) && defined?(::Rails.version)
            m[:frameworks] ||= []
            m[:frameworks] << {
              name: "rails",
              version: ::Rails.version
            }
          end
          m[:git] = git_metadata if git_available
        end
      end

      protected

      def git_available
        @git_available = system("git status 2>&1 > /dev/null") if @git_available.nil?
      end

      def git_metadata
        git_repo = `git config --get remote.origin.url`.strip
        git_branch = `git rev-parse --abbrev-ref HEAD`.strip
        git_sha = `git rev-parse HEAD`.strip

        {
          repository: git_repo,
          branch: git_branch,
          commit: git_sha
        }
      end
    end
  end
end

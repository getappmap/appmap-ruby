# frozen_string_literal: true

module AppMap
  module Service
    class Guesser
      POSSIBLE_PATHS = %w[app/controllers app/models lib]
      class << self
        def guess_name
          reponame = lambda do
            next unless File.directory?('.git')

            repo_name = `git config --get remote.origin.url`.strip
            repo_name.split('/').last.split('.').first unless repo_name == ''
          end
          dirname = -> { Dir.pwd.split('/').last }

          reponame.() || dirname.()
        end

        def guess_paths
          POSSIBLE_PATHS.select { |path| File.directory?(path) }
        end
      end
    end
  end
end
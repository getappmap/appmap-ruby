# frozen_string_literal: true

module AppMap
  module Service
    class Guesser
      POSSIBLE_PATHS = %w[app/controllers app/models lib]
      class << self
        def guess_name
          return Pathname.new(`git rev-parse --show-toplevel`.strip).basename.to_s if File.directory?('.git')
          Dir.pwd.split('/').last
        end

        def guess_paths
          POSSIBLE_PATHS.select { |path| File.directory?(path) }
        end
      end
    end
  end
end
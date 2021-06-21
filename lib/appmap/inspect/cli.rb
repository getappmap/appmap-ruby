require 'appmap/version'
require 'appmap/config'
require 'appmap/node_cli'

module AppMap
  module Inspect
    class CLI < AppMap::NodeCLI
      class << self
        def run
          command = CLI.new(verbose: ENV['DEBUG'] == 'true')
          command.inspect(ARGV)
        end
      end

      def inspect(arguments)
        detect_nodejs
        index_appmaps

        arguments.unshift 'inspect'
        arguments.unshift APPMAP_JS
        arguments.unshift 'node'

        exec(*arguments)
      end
    end
  end
end

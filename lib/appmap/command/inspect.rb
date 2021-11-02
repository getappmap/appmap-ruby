require 'appmap/version'
require 'appmap/node_cli'

module AppMap
  module Command
    class Inspect < AppMap::NodeCLI
      class << self
        def run
          command = Inspect.new(verbose: ENV['DEBUG'] == 'true')
          command.inspect(ARGV)
        end
      end

      def inspect(arguments)
        detect_nodejs

        arguments.unshift 'inspect'
        arguments.unshift APPMAP_JS
        arguments.unshift 'node'

        exec(*arguments)
      end
    end
  end
end

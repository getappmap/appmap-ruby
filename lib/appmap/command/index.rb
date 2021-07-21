require 'appmap/version'
require 'appmap/node_cli'

module AppMap
  module Command
    class Index < AppMap::NodeCLI
      class << self
        def run
          command = Index.new(verbose: ENV['DEBUG'] == 'true')
          command.index(ARGV)
        end
      end

      def index(arguments)
        detect_nodejs

        arguments.unshift 'index'
        arguments.unshift APPMAP_JS
        arguments.unshift 'node'

        exec(*arguments)
      end
    end
  end
end

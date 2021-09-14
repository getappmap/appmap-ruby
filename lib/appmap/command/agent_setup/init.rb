# frozen_string_literal: true

require 'json'
require 'yaml'
require 'appmap/service/guesser'

module AppMap
  module Command
    module AgentSetup
      InitStruct = Struct.new(:config_file)

      class Init < InitStruct
        def perform
          config = {
            'name' => Service::Guesser.guess_name,
            'packages' => Service::Guesser.guess_paths.map { |path| { 'path' => path } }
          }

          result = {
            configuration: {
              filename: config_file,
              contents: YAML.dump(config)
            }
          }

          puts JSON.pretty_generate(result)
        end
      end
    end
  end
end

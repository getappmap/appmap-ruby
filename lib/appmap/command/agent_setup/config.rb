# frozen_string_literal: true

require 'yaml'
require 'appmap/service/guesser'

module AppMap
  module Command
    module AgentSetup
      ConfigStruct = Struct.new(:config_file, :overwrite)

      class Config < ConfigStruct
        class FileExistsError < StandardError; end

        def perform
          raise FileExistsError unless overwrite || !File.exist?(config_file)

          config = {
            'name' => Service::Guesser.guess_name,
            'packages' => Service::Guesser.guess_paths.map { |path| { 'path' => path } },
            'language' => 'ruby',
            'appmap_dir' => 'tmp/appmap'
          }

          File.write(config_file, YAML.dump(config))
        end
      end
    end
  end
end

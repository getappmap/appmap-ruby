# frozen_string_literal: true

module AppMap
  module Command
    InspectStruct = Struct.new(:config)

    class Inspect < InspectStruct
      def perform
        require 'appmap/command/record'

        features = AppMap.inspect(config)
        { version: AppMap::APPMAP_FORMAT_VERSION, metadata: AppMap::Command::Record.detect_metadata, classMap: features }
      end
    end
  end
end

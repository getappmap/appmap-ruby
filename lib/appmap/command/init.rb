# frozen_string_literal: true

module AppMap
  module Command
    InitStruct = Struct.new(:config_file)

    class Init < InitStruct
      def perform
        print "Initializing #{config_file}..."
      end
    end
  end
end
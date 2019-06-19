module AppMap
  module Command
    InspectStruct = Struct.new(:config)

    class Inspect < InspectStruct
      def perform
        AppMap.inspect(config)
      end
    end
  end
end

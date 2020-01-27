module AppMap
  module Command
    StatsStruct = Struct.new(:appmap)

    class Stats < StatsStruct
      def perform(limit: nil)
        require 'appmap/algorithm/stats'
        AppMap::Algorithm::Stats.new(appmap).perform(limit: limit)
      end
    end
  end
end

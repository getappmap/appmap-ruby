module AppMap
  module Config
    # Scan a specific file for AppMap annotations.
    #
    # @appmap
    class File < Path
      # @appmap
      def initialize(path)
        super
      end

      def annotated?
        true
      end
    end
  end
end

module AppMap
  module Config
    # Scan a specific file for AppMap annotations.
    class File < Path
      def annotated?
        true
      end
    end
  end
end

module AppMap
  module Config
    Path = Struct.new(:path) do
      def annotated?
        false
      end

      def <=>(other)
        path <=> other.path
      end

      def module?
        false
      end

      # Automatically determined configurations of child file/module paths.
      def children
        []
      end
    end
  end
end

module AppMap
  module Config
    Path = Struct.new(:path) do
      def <=>(other)
        path <=> other.path
      end

      # Automatically determined configurations of child file/module paths.
      def children
        []
      end
    end
  end
end

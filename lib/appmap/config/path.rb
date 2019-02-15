module AppMap
  module Config
    PathStruct = Struct.new(:path)

    # Path is an abstract configuration of a file, directory, or package.
    class Path < PathStruct
      attr_accessor :mode

      def initialize(path)
        super(path)

        @mode = :implicit
      end

      def <=>(other)
        path <=> other.path
      end

      # Automatically determined configurations of child file/package paths.
      def children
        []
      end
    end
  end
end

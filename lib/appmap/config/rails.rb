module AppMap
  module Config
    # Provides package configuration for the standard Rails directory layout:
    #
    # * app
    # * lib
    #
    # @appmap
    class Rails < Path
      # @appmap
      def initialize(path)
        super
      end

      # @appmap
      def children
        [
          PackageDir.new(File.join(path, 'app'), 'app').tap { |md| md.mode = mode },
          PackageDir.new(File.join(path, 'lib'), 'lib').tap { |md| md.mode = mode }
        ]
      end
    end
  end
end

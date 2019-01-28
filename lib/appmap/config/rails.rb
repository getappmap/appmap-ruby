module AppMap
  module Config
    # Provides module configuration for the standard Rails directory layout:
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
          ModuleDir.new(File.join(path, 'app'), 'app').tap { |md| md.mode = mode },
          ModuleDir.new(File.join(path, 'lib'), 'lib').tap { |md| md.mode = mode }
        ]
      end
    end
  end
end

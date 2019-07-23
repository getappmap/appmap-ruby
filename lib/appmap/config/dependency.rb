module AppMap
  module Config
    DependencyStruct = Struct.new(:id, :gem_name, :file_path, :class_names, :method_name, :static)

    # Loads a specialized dependency.
    #
    # @appmap
    class Dependency < DependencyStruct
      def children
        []
      end
    end
  end
end

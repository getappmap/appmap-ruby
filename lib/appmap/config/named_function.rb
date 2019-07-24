module AppMap
  module Config
    NamedFunctionStruct = Struct.new(:id, :gem_name, :file_path, :class_names, :method_name, :static)

    # Identifies a specific function within a Gem to be instrumented.
    #
    # * `id` A unique identifier for the named function. This is used to associate custom logic with the
    #   named function when the trace events are being handled.
    # * `gem_name` Name of the Gem.
    # * `file_path` Name of the file within the Gem in which the function is located.
    # * `class_names` Array of the module/class name scope which contains the function. For example,
    #   `%w[Rack Handler WEBrick]`.
    # * `method_name` Name of the method within the class name scope.
    # * `static` Whether it's a static or instance method.
    class NamedFunction < NamedFunctionStruct
      def children
        []
      end
    end
  end
end

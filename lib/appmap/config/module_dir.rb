module AppMap
  module Config
    # Scan a directory for AppMap features, treating it as a module and its
    # sub-folders as sub-modules.
    #
    # @appmap
    class ModuleDir < Directory
      attr_reader :module_name, :module_path
      attr_accessor :exclude

      # @appmap
      def initialize(path, module_name, module_path: module_name, exclude: [])
        super(path)
        @module_name = module_name
        @module_path = module_path
        @exclude = exclude || []
      end

      def sub_module_dir(dir)
        ModuleDir.new(::File.join(path, dir), dir, module_path: ::File.join(module_path, dir), exclude: exclude).tap do |m|
          m.mode = mode
        end
      end

      def exclude?(path)
        exclude.member?(path)
      end

      # @appmap
      def children
        child_files + child_modules
      end

      protected

      def child_modules
        ::Dir.new(path).entries.select do |fname|
          !%w[. ..].include?(fname) && ::File.directory?(::File.join(path, fname))
        end.select do |dir|
          !exclude?(::File.join(module_path, dir))
        end.map do |dir|
          sub_module_dir(dir)
        end
      end
    end
  end
end

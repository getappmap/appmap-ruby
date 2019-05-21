module AppMap
  module Config
    # Scan a directory for AppMap features, treating it as a package and its
    # sub-folders as sub-packages.
    #
    # @appmap
    class PackageDir < Directory
      attr_reader :package_name, :package_path
      attr_accessor :exclude

      # @appmap
      def initialize(path, package_name, package_path: package_name, exclude: [])
        super(path)
        @package_name = package_name
        @package_path = package_path
        @exclude = exclude || []
      end

      def sub_package_dir(dir)
        PackageDir.new(::File.join(path, dir), dir, package_path: ::File.join(package_path, dir), exclude: exclude).tap do |m|
          m.mode = mode
        end
      end

      def exclude?(path)
        exclude.member?(path)
      end

      # @appmap
      def children
        child_files.sort + child_packages.sort
      end

      protected

      def child_packages
        ::Dir.new(path).entries.select do |fname|
          !%w[. ..].include?(fname) && ::File.directory?(::File.join(path, fname))
        end.select do |dir|
          !exclude?(::File.join(package_path, dir))
        end.map do |dir|
          sub_package_dir(dir)
        end
      end
    end
  end
end

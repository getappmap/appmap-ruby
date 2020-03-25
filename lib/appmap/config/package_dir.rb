# frozen_string_literal: true

require 'pathname'

module AppMap
  module Config
    # Scan a directory for AppMap features, treating it as a package and its
    # sub-folders as sub-packages.
    #
    # @appmap
    class PackageDir < Directory
      attr_accessor :package_name, :base_path, :exclude

      # @appmap
      def initialize(path, package_name = Pathname.new(path || '').basename.to_s)
        super(path)

        @package_name = package_name
        @base_path = path
        @exclude = []
      end

      def sub_package_dir(dir)
        PackageDir.new(::File.join(path, dir), dir).tap do |m|
          m.base_path = base_path
          m.exclude = exclude
          m.mode = mode
        end
      end

      def exclude?(path)
        relative_path = path.gsub("#{base_path}/", '')
        exclude.member?(relative_path)
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
          !exclude?(::File.join(path, dir))
        end.map do |dir|
          sub_package_dir(dir)
        end
      end
    end
  end
end

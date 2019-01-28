module AppMap
  module Config
    # A normal directory is scanned for AppMap features without interpreting the
    # directory as a code module.
    #
    # @appmap
    class Directory < Path
      # @appmap
      def initialize(path)
        super
      end

      # @appmap
      def children
        child_files.sort + child_directories.sort
      end

      protected

      def ruby_file?(path)
        ::File.file?(path) && (path =~ /\.rb$/ || ruby_shebang?(path))
      end

      def ruby_shebang?(path)
        lines = begin
          ::File.read(path).split("\n")
        rescue ArgumentError => e
          if e.message.index 'invalid byte sequence'
            warn "Unable to load file #{path.inspect} : #{e.message}"
            return false
          end
          raise
        end
        lines[0] && lines[0].index('#!/usr/bin/env ruby') == 0
      end

      def child_files
        expand_path = ->(fname) { ::File.join(path, fname) }
        Dir.new(path).entries.select do |fname|
          ::File.file?(expand_path.call(fname)) &&
            !::File.symlink?(expand_path.call(fname)) &&
            ruby_file?(expand_path.call(fname))
        end.map do |fname|
          File.new(expand_path.call(fname)).tap do |f|
            f.mode = mode
          end
        end
      end

      def child_directories
        File.new(path).entries.select do |fname|
          !%w[. ..].include?(fname) && !::File.directory?(fname)
        end.map do |dir|
          ModuleDir.new(dir, [module_name, dir].join('/')).tap do |m|
            m.mode = mode
          end
        end
      end
    end
  end
end

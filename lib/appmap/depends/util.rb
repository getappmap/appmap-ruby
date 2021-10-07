require 'fileutils'

module AppMap
  module Depends
    module Util
      extend self

      def normalize_path(path, pwd: Dir.pwd)
        normalize_path_fn(pwd).(path)
      end

      def normalize_paths(paths, pwd: Dir.pwd)
        paths.map(&normalize_path_fn(pwd))
      end
            
      def delete_appmap(appmap_path)
        FileUtils.rm_rf(appmap_path)
        appmap_file_path = [ appmap_path, 'appmap.json' ].join('.')
        File.unlink(appmap_file_path) if File.exist?(appmap_file_path)
      rescue
        warn "Unable to delete AppMap: #{$!}"
      end

      private

      def normalize_path_fn(pwd)
        lambda do |path|
          next path if AppMap::Util.blank?(path)

          path = path[pwd.length + 1..-1] if path.index(pwd) == 0
          path.split(':')[0]
        end  
      end
    end
  end
end

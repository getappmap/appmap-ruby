# frozen_string_literal: true

require 'fileutils'
require 'appmap/service/guesser'
require 'appmap/util'

module AppMap
  module Command
    InitStruct = Struct.new(:config_file)

    class Init < InitStruct
      def perform
        if File.exist?(config_file)
          puts AppMap::Util.color(%(The AppMap config file #{config_file} already exists.), :magenta)
          return
        end

        ensure_directory_exists

        config = {
          'name' => Service::Guesser.guess_name,
          'packages' => Service::Guesser.guess_paths.map { |path| { 'path' => path } }
        }
        content = YAML.dump(config).gsub("---\n", '')

        File.write(config_file, content)
        puts AppMap::Util.color(
          %(The following AppMap config file #{config_file} has been created:),
          :green
        )
        puts content
      end

      private

      def ensure_directory_exists
        dirname = File.dirname(config_file)
        FileUtils.mkdir_p(dirname) unless File.directory?(dirname)
      end
    end
  end
end

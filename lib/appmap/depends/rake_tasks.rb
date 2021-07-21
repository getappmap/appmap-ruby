# frozen_string_literal: true

require 'rake'
require 'appmap/node_cli'
require_relative 'api'

module AppMap
  module Depends
    module RakeTasks
      extend self
      extend Rake::DSL

      def depends_api
        AppMap::Depends::API.new(Rake.verbose == true)
      end

      def configuration
        AppMap.configuration
      end

      def define_tasks
        namespace :depends do
          task :modified do
            @appmap_modified_files = depends_api.modified(appmap_dir: configuration.appmap_dir, base_dir: configuration.depends_config.base_dir)
            depends_api.report_list 'Out of date', @appmap_modified_files
          end
      
          task :test_file_report do
            @appmap_test_file_report = depends_api.inspect_test_files(appmap_dir: configuration.appmap_dir, test_file_patterns: configuration.depends_config.test_file_patterns)
            @appmap_test_file_report.report
          end

          task :run_tests do
            if @appmap_test_file_report
              @appmap_test_file_report.clean_appmaps
              @appmap_modified_files += @appmap_test_file_report.modified_files
            end
      
            if @appmap_modified_files.empty?
              warn 'AppMaps are up to date'
              next
            end
      
            start_time = Time.current
            depends_api.run_tests(@appmap_modified_files, appmap_dir: configuration.appmap_dir)

            warn "Tests succeeded - removing out of date AppMaps."
            removed = depends_api.remove_out_of_date_appmaps(start_time, appmap_dir: configuration.appmap_dir, base_dir: configuration.depends_config.base_dir)
            warn "Removed out of date AppMaps: #{removed.join(' ')}" unless removed.empty?
          end

          desc configuration.depends_config.description
          task :update => [ :modified, :test_file_report, :run_tests ] + configuration.depends_config.dependent_tasks
        end
      end
    end
  end
end

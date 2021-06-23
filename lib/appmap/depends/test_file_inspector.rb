# frozen_string_literal: true

require 'json'

module AppMap
  module Depends
    class TestFileInspector
      TestReport = Struct.new(:metadata_files, :added, :removed, :changed, :failed) do
        private_methods :metadata_files

        def to_s
          report = []
          report << "Added test files   : #{added.to_a.join(' ')}" unless added.empty?
          report << "Removed test files : #{removed.to_a.join(' ')}" unless removed.empty?
          report << "Changed test files : #{changed.to_a.join(' ')}" unless changed.empty?
          report << "Failed test files  : #{failed.to_a.join(' ')}" unless failed.empty?
          report.compact.join("\n")
        end

        def report
          warn to_s unless empty?
        end

        def empty?
          [ added, removed, changed, failed ].all?(&:empty?)
        end

        def modified_files
          added + changed + failed
        end

        # Delete AppMaps which depend on test cases that have been deleted.
        def clean_appmaps
          return if removed.empty?

          count = metadata_files.each_with_object(0) do |metadata_file, count|
            metadata = JSON.parse(File.read(metadata_file))
            source_location = Util.normalize_path(metadata['source_location'])
            appmap_path = File.join(metadata_file.split('/')[0...-1])
    
            if source_location && removed.member?(source_location)
              Util.delete_appmap(appmap_path)
              count += 1
            end
          end
          count
        end
      end

      attr_reader :test_dir
      attr_reader :test_file_patterns

      def initialize(test_dir, test_file_patterns)
        @test_dir = test_dir
        @test_file_patterns = test_file_patterns
      end

      def report
        metadata_files = Dir.glob(File.join(test_dir, '**', 'metadata.json'))
        source_locations = Set.new
        changed_test_files = Set.new
        failed_test_files = Set.new
        metadata_files.each do |metadata_file|
          metadata = JSON.parse(File.read(metadata_file))
          appmap_path = File.join(metadata_file.split('/')[0...-1])

          appmap_mtime = File.read(File.join(appmap_path, 'mtime')).to_i
          source_location = Util.normalize_path(metadata['source_location'])
          test_status = metadata['test_status']
          next unless source_location && test_status

          source_location_mtime = (File.stat(source_location).mtime.to_f * 1000).to_i rescue nil
          source_locations << source_location
          if source_location_mtime
            changed_test_files << source_location if source_location_mtime > appmap_mtime
            failed_test_files << source_location unless test_status == 'succeeded'
          end
        end
  
        test_files = Set.new(test_file_patterns.map(&Dir.method(:glob)).flatten)
        added_test_files = test_files - source_locations
        changed_test_files -= added_test_files
        removed_test_files = source_locations - test_files
    
        TestReport.new(metadata_files, added_test_files, removed_test_files, changed_test_files, failed_test_files)
      end
    end
  end
end

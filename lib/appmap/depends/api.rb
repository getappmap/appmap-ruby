# frozen_string_literal: true

require_relative 'util'
require_relative 'node_cli'
require_relative 'test_file_inspector'
require_relative 'test_runner'

module AppMap
  module Depends
    class API
      attr_reader :verbose

      def initialize(verbose)
        @verbose = verbose
      end

      # Compute the set of test files which are "out of date" with respect to source files in +base_dir+.
      # Use AppMaps in +appmap_dir+ to make this computation.
      def modified(appmap_dir:, base_dir:)
        depends = AppMap::Depends::NodeCLI.new(verbose: verbose, appmap_dir: appmap_dir)
        depends.base_dir = base_dir if base_dir
        test_files = depends.depends

        Set.new prune_directory_prefix(test_files)
      end

      # Compute which test case files have been added, removed, changed, or failed, relative to the
      # AppMaps.
      def inspect_test_files(appmap_dir:, test_file_patterns:)
        inspector = AppMap::Depends::TestFileInspector.new(appmap_dir, test_file_patterns)
        inspector.report
      end

      # Print a brief report to STDERR.
      def report_list(title, files)
        warn [ title, files.to_a.sort.join(' ') ].join(': ') unless files.empty?
      end

      # Run the specified test files. After running the tests, update the AppMap index.
      # TODO: If the tests fail, this method will raise, and the index won't be updated.
      # What's the right behavior for the index if there is a test failure? Current behavior may not match
      # user expectations.
      def run_tests(test_files, appmap_dir:)
        test_files = test_files.to_a.sort
        warn "Running tests: #{test_files.join(' ')}"

        TestRunner.new(test_files).run

        AppMap::NodeCLI.new(verbose: verbose, appmap_dir: appmap_dir).index_appmaps
      end

      # Remove out-of-date AppMaps which are unmodified +since+ the start time. This operation is used to remove AppMaps
      # that were previously generated from a test case that has been removed from a test file.
      #
      # * +since+ an instance of Time
      def remove_out_of_date_appmaps(since, appmap_dir:, base_dir:)
        since_ms = ( since.to_f * 1000 ).to_i

        depends = AppMap::Depends::NodeCLI.new(verbose: verbose, appmap_dir: appmap_dir)
        depends.base_dir = base_dir if base_dir
        depends.field = nil
        out_of_date_appmaps = depends.depends
        removed = []
        out_of_date_appmaps.each do |appmap_path|
          mtime_path = File.join(appmap_path, 'mtime')
          next unless File.exist?(mtime_path)

          appmap_mtime = File.read(mtime_path).to_i
          if appmap_mtime < since_ms
            Util.delete_appmap appmap_path
            removed << appmap_path
          end
        end
        removed.sort
      end

      protected

      def prune_directory_prefix(files)
        Array(files).map(&Util.method(:normalize_path))
      end
    end
  end
end

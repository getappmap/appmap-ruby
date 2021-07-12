# frozen_string_literal: true

require 'appmap/service/test_framework_detector'

module AppMap
  module Service
    class IntegrationTestPathFinder
      def initialize(base_path = '')
        @base_path = base_path
      end

      def find
        @paths ||= begin
          paths = { rspec: [], minitest: [], cucumber: [] }
          paths[:rspec] = find_rspec_paths if TestFrameworkDetector.rspec_present?
          paths[:minitest] = find_minitest_paths if TestFrameworkDetector.minitest_present?
          paths[:cucumber] = find_cucumber_paths if TestFrameworkDetector.cucumber_present?
          paths
        end
      end

      def count_paths
        find.flatten(2).length - 3
      end

      private

      def find_rspec_paths
        find_non_empty_paths(%w[spec/controllers spec/requests spec/integration spec/api spec/features spec/system])
      end


      def find_minitest_paths
        top_level_paths = %w[test/controllers test/integration]
        children_paths = Dir.glob('test/**/{controllers,integration}')
        find_non_empty_paths((top_level_paths + children_paths).uniq).sort
      end

      def find_cucumber_paths
        find_non_empty_paths(%w[features])
      end

      def find_non_empty_paths(paths)
        paths.select { |path| Dir.exist?(@base_path + path) && !Dir.empty?(@base_path + path) }
      end
    end
  end
end

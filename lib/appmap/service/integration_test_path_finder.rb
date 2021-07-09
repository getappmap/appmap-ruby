# frozen_string_literal: true

require 'appmap/service/test_framework_detector'

module AppMap
  module Service
    class IntegrationTestPathFinder
      class << self
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
          find_non_empty_paths(Dir.glob('test/**/{controllers,integration}').sort)
        end

        def find_cucumber_paths
          find_non_empty_paths(%w[features])
        end

        def find_non_empty_paths(paths)
          paths.select { |path| Dir.exist?(path) && !Dir.empty?(path) }
        end
      end
    end
  end
end

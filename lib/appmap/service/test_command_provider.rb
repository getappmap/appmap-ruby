# frozen_string_literal: true

require 'appmap/service/test_framework_detector'
require 'appmap/service/integration_test_path_finder'

module AppMap
  module Service
    class TestCommandProvider
      class << self
        def all
          commands = []

          if TestFrameworkDetector.rspec_present? && !integration_test_paths[:rspec].empty?
            commands << {
              framework: :rspec,
              command: {
                program: 'bundle',
                args: %w[exec rspec] + integration_test_paths[:rspec].map { |path| "./#{path}" },
                environment: { APPMAP: 'true', DISABLE_SPRING: 'true' }
              }
            }
          end

          if TestFrameworkDetector.minitest_present? && !integration_test_paths[:minitest].empty?
            commands += minitest_commands
          end
          if TestFrameworkDetector.cucumber_present? && !integration_test_paths[:cucumber].empty?
            commands << {
              framework: :cucumber,
              command: {
                program: 'bundle',
                args: %w[exec cucumber],
                environment: { APPMAP: 'true', DISABLE_SPRING: 'true' }
              }
            }
          end

          commands
        end

        private

        def minitest_commands
          if Gem.loaded_specs.has_key?('rails')
            [
              {
                framework: :minitest,
                command: {
                  program: 'bundle',
                  args: %w[exec rails test] + integration_test_paths[:minitest].map { |path| "./#{path}" },
                  environment: { APPMAP: 'true', DISABLE_SPRING: 'true' }
                }
              }
            ]
          else
            integration_test_paths[:minitest].map do |path|
              {
                framework: :minitest,
                command: {
                  program: 'bundle',
                  args: ['exec', 'ruby', "./#{path}"],
                  environment: { APPMAP: 'true', DISABLE_SPRING: 'true' }
                }
              }
            end
          end
        end

        def integration_test_paths
          @paths ||= Service::IntegrationTestPathFinder.new.find
        end
      end
    end
  end
end

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
              command: "APPMAP=true bundle exec rspec #{integration_test_paths[:rspec].join(' ')}"
            }
          end

          if TestFrameworkDetector.minitest_present? && !integration_test_paths[:minitest].empty?
            commands << {
              framework: :minitest,
              command: minitest_command
            }
          end

          if TestFrameworkDetector.cucumber_present? && !integration_test_paths[:cucumber].empty?
            commands << {
              framework: :cucumber,
              command: 'APPMAP=true bundle exec cucumber'
            }
          end

          commands
        end

        private

        def minitest_command
          if Gem.loaded_specs.has_key?('rails')
            "APPMAP=true bundle exec rails test #{integration_test_paths[:minitest].join(' ')}"
          else
            subcommands = integration_test_paths[:minitest].map { |path| "APPMAP=true bundle exec ruby #{path}" }
            subcommands.join(' && ')
          end
        end

        def integration_test_paths
          @paths ||= Service::IntegrationTestPathFinder.find
        end
      end
    end
  end
end

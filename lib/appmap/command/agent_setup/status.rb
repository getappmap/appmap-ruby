# frozen_string_literal: true

require 'json'
require 'appmap/service/config_analyzer'
require 'appmap/service/integration_test_path_finder'
require 'appmap/service/test_command_provider'

module AppMap
  module Command
    module AgentSetup
      StatusStruct = Struct.new(:config_file)

      class Status < StatusStruct
        def perform
          status = {
            test_commands: Service::TestCommandProvider.all,
            properties: {
              config: {
                app: config_analyzer.app_name,
                present: config_analyzer.present?,
                valid: config_analyzer.valid?
              },
              project: {
                agentVersion: AppMap::VERSION,
                language: 'ruby',
                remoteRecordingCapable: Gem.loaded_specs.has_key?('rails'),
                integrationTests: Service::IntegrationTestPathFinder.new.count_paths > 0
              }
            }
          }

          puts JSON.pretty_generate(status)
        end

        private

        def config_analyzer
          @config_analyzer ||= Service::ConfigAnalyzer.new(config_file)
        end
      end
    end
  end
end

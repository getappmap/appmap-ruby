# frozen_string_literal: true

require 'json'
require 'appmap/service/config_analyzer'

module AppMap
  module Command
    module AgentSetup
      StatusStruct = Struct.new(:config_file)

      class Status < StatusStruct
        def perform
          status = {
            :properties => {
              :config => {
                :app => config_analyzer.app_name,
                :present => config_analyzer.present?,
                :valid => config_analyzer.valid?
              },
              :project => {
                :agentVersionProject => AppMap::VERSION,
                :language => 'ruby',
                :remoteRecordingCapable => Gem.loaded_specs.has_key?('rails'),
                :integrationTests => false #TODO
              }
            }
          }

          puts status.to_json
        end

        private

        def config_analyzer
          @config_analyzer ||= Service::ConfigAnalyzer.new(config_file)
        end
      end
    end
  end
end

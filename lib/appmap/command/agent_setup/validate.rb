# frozen_string_literal: true

require 'json'
require 'appmap/service/validator/config_validator'

module AppMap
  module Command
    module AgentSetup
      ValidateStruct = Struct.new(:config_file)

      class Validate < ValidateStruct
        def perform
          puts JSON.pretty_generate(config_validator.valid? ? [] : config_validator.violations.map(&:to_h))
        end

        private

        def config_validator
          @validator ||= Service::Validator::ConfigValidator.new(config_file)
        end
      end
    end
  end
end

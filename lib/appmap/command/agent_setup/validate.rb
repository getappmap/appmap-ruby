# frozen_string_literal: true

require 'json'
require 'appmap/service/validator/config_validator'

module AppMap
  module Command
    module AgentSetup
      ValidateStruct = Struct.new(:config_file)

      class Validate < ValidateStruct
        def perform
          schema_path = File.expand_path('../../../../../config-schema.yml', __FILE__)
          schema = YAML.safe_load(File.read(schema_path))
          result = {
            version: 2,
            errors: config_validator.valid? ? [] : config_validator.violations.map(&:to_h),
            schema: schema
          }
          puts JSON.pretty_generate(result)
        end

        private

        def config_validator
          @validator ||= Service::Validator::ConfigValidator.new(config_file)
        end
      end
    end
  end
end

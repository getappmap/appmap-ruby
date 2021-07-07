# frozen_string_literal: true

require 'appmap/service/validator/violation'

module AppMap
  module Service
    module Validator
      class ConfigValidator
        attr_reader :config, :violations

        def initialize(config_file)
          @config_file = config_file
          @violations = []
          @config = load_config
        end

        def valid?
          validate_config_presence
          @violations.length == 0
        end

        private

        def present?
          File.exist?(@config_file)
        end

        def load_config
          AppMap::Config.load_from_file(@config_file) if present?
        rescue StandardError => e
          @violations << Violation.error(
            filename: @config_file,
            message: 'AppMap configuration is not valid YAML',
            detailed_message: e.message
          )
          nil
        end

        def validate_config_presence
          unless present?
            @violations << Violation.error(
              filename: @config_file,
              message: 'AppMap configuration file does not exist'
            )
          end
        end
      end
    end
  end
end

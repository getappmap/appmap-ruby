# frozen_string_literal: true

require 'appmap/service/validator/violation'

module AppMap
  module Service
    module Validator
      class ConfigValidator
        attr_reader :violations

        def initialize(config_file)
          @config_file = config_file
          @violations = []
        end

        def config
          parse_config
        end

        def valid?
          validate_ruby_version
          validate_config_presence
          parse_config
          validate_config_load
          @violations.empty?
        end

        private

        def present?
          File.exist?(@config_file)
        end

        def parse_config
          return unless present?

          @config_data ||= YAML.load_file(@config_file)
        rescue Psych::SyntaxError => e
          @violations << Violation.error(
            filename: @config_file,
            message: 'AppMap configuration is not valid YAML',
            detailed_message: e.message
          )
          nil
        end

        def validate_config_load
          return unless @config_data

          AppMap::Config.load(@config_data)
        rescue StandardError => e
          @violations << Violation.error(
            filename: @config_file,
            message: 'AppMap configuration could not be loaded',
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

        def validate_ruby_version
          unless RUBY_VERSION =~ AppMap::SUPPORTED_RUBY_VERSIONS_REGEX
            @violations << Violation.error(
              message: "AppMap does not support Ruby #{RUBY_VERSION}. " \
                "Supported versions are: #{AppMap::SUPPORTED_RUBY_VERSIONS.join(', ')}."
              )
          end
        end
      end
    end
  end
end

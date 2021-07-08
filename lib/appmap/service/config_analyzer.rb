# frozen_string_literal: true

require 'appmap/service/validator/config_validator'

module AppMap
  module Service
    class ConfigAnalyzer
      attr_reader :config_error

      def initialize(config_file)
        @config_file = config_file
      end

      def app_name
        config_validator.config.to_h['name'] if present?
      end

      def present?
        File.exist?(@config_file)
      end

      def valid?
        config_validator.valid?
      end

      private

      def config_validator
        @validator ||= AppMap::Service::Validator::ConfigValidator.new(@config_file)
      end
    end
  end
end

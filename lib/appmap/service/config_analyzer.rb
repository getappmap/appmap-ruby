# frozen_string_literal: true

module AppMap
  module Service
    class ConfigAnalyzer
      attr_reader :config_error

      def initialize(config_file)
        @config_file = config_file
        @config = load_config
      end

      def app_name
        @config.to_h[:name] if present?
      end

      def present?
        File.exist?(@config_file)
      end

      def valid?
        present? && @config.to_h.key?(:name) && @config.to_h.key?(:packages)
      end

      private

      def load_config
        AppMap::Config.load_from_file @config_file if present?
      rescue
        nil
      end
    end
  end
end
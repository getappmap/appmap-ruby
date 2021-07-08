# frozen_string_literal: true

module AppMap
  module Service
    module Validator
      class Violation
        attr_reader :level, :setting, :filename, :message, :detailed_message, :help_urls

        class << self
          def error(message:, setting: nil, filename: nil, detailed_message: nil, help_urls: nil)
            self.new(
              level: :error,
              message: message,
              setting: setting,
              filename: filename,
              detailed_message: detailed_message,
              help_urls: help_urls
            )
          end

          def warning(message:, setting: nil, filename: nil, detailed_message: nil, help_urls: nil)
            self.new(
              level: :warning,
              message: message,
              setting: setting,
              filename: filename,
              detailed_message: detailed_message,
              help_urls: help_urls
            )
          end
        end

        def initialize(level:, message:, setting:, filename:, detailed_message:, help_urls:)
          @level = level
          @setting = setting
          @filename = filename
          @message = message
          @detailed_message = detailed_message
          @help_urls = help_urls
        end

        def to_h
          instance_variables.each_with_object({}) do |var, hash|
            hash[var.to_s.delete("@")] = self.instance_variable_get(var)
          end.compact
        end
      end
    end
  end
end

require 'active_support'
require 'active_support/core_ext'

module AppMap
  module Swagger
    # Transform raw Swagger into a "stable" variant. For example, remove descriptions
    # and parameter examples, whose variance does not substantially affect the API.
    class Stable
      def initialize(swagger_yaml)
        @swagger_yaml = swagger_yaml
      end

      def perform
        clean_only = nil
        clean = lambda do |obj, properties = %w[description example]|
          return obj.each(&clean_only.(properties)) if obj.is_a?(Array)
          return unless obj.is_a?(Hash)

          properties.each { |property| obj.delete property }

          obj.each do |key, value|
            # Don't clean 'description' from within 'properties'
            props = key == 'properties' ? %w[example] : properties
            clean_only.(props).(value)
          end

          obj
        end

        clean_only = lambda do |properties|
          lambda do |example|
            clean.(example, properties)
          end
        end

        clean.(@swagger_yaml.deep_dup)
      end
    end
  end
end

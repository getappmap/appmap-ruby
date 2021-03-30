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
        clean = lambda do |obj|
          return obj.each(&clean) if obj.is_a?(Array)
          return unless obj.is_a?(Hash)

          obj.delete 'description'
          obj.delete 'example'

          obj.each_value(&clean)

          obj
        end

        clean.(@swagger_yaml.deep_dup)
      end
    end
  end
end

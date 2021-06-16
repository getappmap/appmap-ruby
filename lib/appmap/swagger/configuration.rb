module AppMap
  module Swagger
    class Configuration
      DEFAULT_VERSION = '1.0'
      DEFAULT_OUTPUT_DIR = 'swagger'
      DEFAULT_APPMAP_DIR = 'tmp/appmap'
      DEFAULT_DESCRIPTION = 'Generate Swagger from AppMaps'

      attr_accessor :project_name,
        :project_version,
        :output_dir,
        :appmap_dir,
        :description
      attr_writer :template

      def initialize
        @project_name = default_project_name
        @project_version = DEFAULT_VERSION
        @output_dir = DEFAULT_OUTPUT_DIR
        @appmap_dir = DEFAULT_APPMAP_DIR
        @description = DEFAULT_DESCRIPTION
      end

      def template
        @template || default_template
      end

      def default_template
        YAML.load <<~TEMPLATE
          openapi: 3.0.1
          info:
            title: #{project_name}
            version: #{project_version}
          paths:
          components:
          servers:
          - url: http://{defaultHost}
            variables:
              defaultHost:
                default: localhost:3000
          TEMPLATE
      end

      def default_project_name
        # https://www.rubydoc.info/docs/rails/Module#module_parent_name-instance_method
        module_parent_name = ->(cls) { cls.name =~ /::[^:]+\Z/ ? $`.freeze : nil }

        if defined?(::Rails)
          [module_parent_name.(::Rails.application.class).humanize.titleize, "API"].join(" ")
        else
          "MyProject API"
        end
      end
    end
  end
end

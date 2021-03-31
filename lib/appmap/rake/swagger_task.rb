# frozen_string_literal: true

require 'appmap/swagger/stable'

module AppMap
  module Rake
    class SwaggerTask < ::Rake::TaskLib
      DEFAULT_APPMAP_DIR = 'tmp/appmap'
      DEFAULT_OUTPUT_DIR = 'swagger'
      DEFAULT_SWAGGERGEN = './node_modules/@appland/appmap-swagger/cli.js'

      attr_accessor :name, :verbose, :swaggergen, :appmap_dir, :output_dir, :project_name, :project_version

      def initialize(*args, &task_block)
        @name            = args.shift || :swagger
        @verbose         = true
        @swaggergen      = DEFAULT_SWAGGERGEN
        @appmap_dir      = DEFAULT_APPMAP_DIR
        @output_dir      = DEFAULT_OUTPUT_DIR
        @project_name    = \
          if defined?(Rails)
            [ Rails.application.class.parent_name.humanize.titleize, 'API' ].join(' ')
          else
            'MyProject API'
          end
        @project_version = 'v1.0'


        define(args, &task_block)
      end

      def run_task(verbose)
        FileUtils.mkdir_p output_dir

        do_fail = lambda do |msg|
          warn msg if verbose
          exit $?.exitstatus || 1
        end

        return do_fail.(%Q('node' not found; please install NodeJS)) unless system('node --version')
        return do_fail.(%Q('#{swaggergen}' not found; please install appmap-swagger from NPM)) unless File.exists?(swaggergen)

        warn swagger_command.join(' ') if verbose

        swagger_raw = `#{swagger_command.join(' ')}`.strip
        return do_fail.(%Q(Swagger generation failed: #{swagger_raw})) if $?.exitstatus != 0

        gen_swagger = YAML.load(swagger_raw)
        gen_swagger_stable = AppMap::Swagger::Stable.new(gen_swagger).perform

        swagger = swagger_template.merge(gen_swagger)
        File.write File.join(output_dir, 'openapi.yaml'), YAML.dump(swagger)

        swagger = swagger_template.merge(gen_swagger_stable)
        File.write File.join(output_dir, 'openapi_stable.yaml'), YAML.dump(swagger)
      end

      def swagger_template
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

      def swagger_command
        [ 'node', swaggergen, 'generate', '--directory', appmap_dir ]
      end

      private

      # This bit of black magic - https://github.com/rspec/rspec-core/blob/main/lib/rspec/core/rake_task.rb#L110
      def define(args, &task_block)
        desc "Generate Swagger from AppMaps" unless ::Rake.application.last_description

        task(name, *args) do |_, task_args|
          RakeFileUtils.__send__(:verbose, verbose) do
            task_block.call(*[self, task_args].slice(0, task_block.arity)) if task_block
            run_task verbose
          end
        end
      end
    end
  end
end
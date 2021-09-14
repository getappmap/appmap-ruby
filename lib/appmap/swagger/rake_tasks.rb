require 'rake'
require 'yaml'
require 'fileutils'
require 'appmap/node_cli'
require 'appmap/swagger/markdown_descriptions'
require 'appmap/swagger/stable'

module AppMap
  module Swagger
    module RakeTasks
      extend self
      extend Rake::DSL

      def configuration
        AppMap.configuration
      end

      def define_tasks
        generate_swagger = lambda do |t, args|
          appmap_js = AppMap::NodeCLI.new(verbose: Rake.verbose == true)

          FileUtils.mkdir_p configuration.swagger_config.output_dir

          cmd = %w[swagger]
  
          swagger_raw, = appmap_js.command(cmd)

          gen_swagger = YAML.load(swagger_raw)
          gen_swagger_full = AppMap::Swagger::MarkdownDescriptions.new(gen_swagger).perform
          gen_swagger_stable = AppMap::Swagger::Stable.new(gen_swagger).perform
  
          swagger = configuration.swagger_config.template.merge(gen_swagger_full)
          File.write File.join(configuration.swagger_config.output_dir, 'openapi.yaml'), YAML.dump(swagger)
  
          swagger = configuration.swagger_config.template.merge(gen_swagger_stable)
          File.write File.join(configuration.swagger_config.output_dir, 'openapi_stable.yaml'), YAML.dump(swagger)  
        end

        desc configuration.swagger_config.description
        task :swagger, &generate_swagger
      end
    end
  end
end

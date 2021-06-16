require 'rake'
require 'appmap/swagger/appmap_js'
require 'appmap/swagger/markdown_descriptions'
require 'appmap/swagger/stable'

module AppMap
  module Swagger
    module RakeTasks
      extend self
      extend Rake::DSL

      def define_tasks(configuration = Configuration.new)
        generate_swagger = lambda do |t, args|
          appmap_js = AppMapJS.new(verbose: Rake.verbose == true)
          appmap_js.detect_nodejs

          FileUtils.mkdir_p configuration.output_dir

          cmd = %w[swagger]
          cmd << '--appmap-dir'
          cmd << configuration.appmap_dir
  
          swagger_raw, = appmap_js.command(cmd)

          gen_swagger = YAML.load(swagger_raw)
          gen_swagger_full = AppMap::Swagger::MarkdownDescriptions.new(gen_swagger).perform
          gen_swagger_stable = AppMap::Swagger::Stable.new(gen_swagger).perform
  
          swagger = configuration.template.merge(gen_swagger_full)
          File.write File.join(configuration.output_dir, 'openapi.yaml'), YAML.dump(swagger)
  
          swagger = configuration.template.merge(gen_swagger_stable)
          File.write File.join(configuration.output_dir, 'openapi_stable.yaml'), YAML.dump(swagger)  
        end

        desc configuration.description
        task :swagger, &generate_swagger
      end
    end
  end
end

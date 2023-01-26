require "rails_helper"

RSpec.configure do |config|
  # Specify a root folder where Swagger JSON files are generated
  # NOTE: If you"re using the rswag-api to serve API descriptions, you"ll need
  # to ensure that it"s configured to serve Swagger from the same folder
  config.swagger_root = Rails.root.join("swagger").to_s

  # Define one or more Swagger documents and provide global metadata for each one
  # When you run the "rswag:specs:swaggerize" rake task, the complete Swagger will
  # be generated at the provided relative path under swagger_root
  # By default, the operations defined in spec files are added to the first
  # document below. You can override this behavior by adding a swagger_doc tag to the
  # the root example_group in your specs, e.g. describe "...", swagger_doc: "v2/swagger.json"
  config.swagger_docs = {
    "v1/api_v1.json" => {
      openapi: "1.0",
      info: {
        title: "Rails 6 Users App API V1",
        version: "1.0.0",
        description: "Access resources via API."
      },
      paths: {},
      servers: [
        {
          url: "http://127.0.0.1/",
          description: "Development server"
        },
      ],
      security: [],
      components: {
        securitySchemes: {
          "api-key": {
            type: :apiKey,
            name: "api-key",
            in: :header,
            description: "API Key authentication.

Authentication for some endpoints."
          }
        },
        parameters: {
          pageParam: {
            in: :query,
            name: :page,
            required: false,
            description: "Pagination page",
            schema: {
              type: :integer,
              format: :int32,
              minimum: 1,
              default: 1
            }
          },
          perPageParam10to1000: {
            in: :query,
            name: :per_page,
            required: false,
            description: "Page size (the number of items to return per page). \
The default maximum value can be overridden by \"API_PER_PAGE_MAX\" environment variable.",
            schema: {
              type: :integer,
              format: :int32,
              minimum: 1,
              maximum: 1000,
              default: 10
            }
          },
        },
        schemas: {}
      }
    }
  }

  # Specify the format of the output Swagger file when running "rswag:specs:swaggerize".
  # Defaults to json. Accepts ":json" and ":yaml".
  config.swagger_format = :json
end

require_relative '../rails_spec_helper'

describe 'rake appmap:swagger' do
  include_context 'Rails app pg database', "spec/fixtures/rails6_users_app" unless use_existing_data?
  include_context 'rails integration test setup'

  unless use_existing_data?
    before(:all) do
      @app.run_cmd './bin/rake appmap:swagger'
    end
  end

  # The swagger-building logic is mostly in the JS code. So what we are really testing here
  # is the Rails integration - the rake task and integration with the appmap.yml.
  it 'generates openapi_stable.yml' do
    swagger = YAML.load(File.read(File.join(tmpdir, 'swagger', 'openapi_stable.yaml'))).deep_symbolize_keys

    expect(swagger).to eq(YAML.load(<<~YAML
      :openapi: 3.0.1
      :info:
        :title: Usersapp API
        :version: 1.1.0
      :paths:
        :/api/users:
          :get:
            :responses:
              :200:
                :content:
                  :application/json: {}
            :requestBody:
              :content: {}
          :post:
            :responses:
              :201:
                :content:
                  :application/json: {}
              :422:
                :content:
                  :application/json: {}
            :requestBody:
              :content:
                :application/x-www-form-urlencoded:
                  :schema:
                    :type: object
                    :properties:
                      :login:
                        :type: string
                      :password:
                        :type: string
                      :user:
                        :type: object
                        :properties:
                          :login:
                            :type: string
                          :password:
                            :type: string
        :/users:
          :get:
            :responses:
              :200:
                :content:
                  :text/html: {}
        :/users/{id}:
          :get:
            :responses:
              :200:
                :content:
                  :text/plain: {}
            :parameters:
            - :name: id
              :in: path
              :schema:
                :type: string
              :required: true
      :components:
        :securitySchemes: {}
      :servers:
      - :url: http://{defaultHost}
        :variables:
          :defaultHost:
            :default: localhost:3000
      YAML
    ))
  end
end

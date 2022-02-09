require_relative '../rails_spec_helper'

describe 'rake appmap:swagger' do
  include_context 'Rails app pg database', "spec/fixtures/rails6_users_app" unless use_existing_data?
  include_context 'rails integration test setup'

  def run_spec(spec_name)
    cmd = <<~CMD.gsub "\n", ' '
      docker-compose run --rm -e RAILS_ENV=test -e APPMAP=true
      -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec #{spec_name}
    CMD
    run_cmd cmd, chdir: fixture_dir
  end

  def generate_swagger
    cmd = <<~CMD.gsub "\n", ' '
      docker-compose run --rm -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rake appmap:swagger
    CMD
    run_cmd cmd, chdir: fixture_dir
  end

  unless use_existing_data?
    before(:all) do
      generate_swagger
    end
  end

  # The swagger-building logic is mostly in the JS code. So what we are really testing here
  # is the Rails integration - the rake task and integration with the appmap.yml.
  it 'generates openapi_stable.yml' do
    swagger = YAML.load(File.read(File.join(tmpdir, 'swagger', 'openapi_stable.yaml'))).deep_symbolize_keys

    expect(swagger).to eq(YAML.load(<<~YAML
      :openapi: 3.0.1
      :info:
        :title: My project
        :version: v1
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

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
  # And of course the bundling of the JS code by the appmap gem.
  it 'generates openapi_stable.yml' do
    swagger = YAML.load(File.read(File.join(tmpdir, 'swagger', 'openapi_stable.yaml'))).deep_symbolize_keys

    expect(swagger).to match(
      hash_including(
        openapi: /^\d\.\d\.\d$/,
        info: {
          title: 'Usersapp API',
          version: '1.1.0'
        },
        paths: hash_including(
          :'/api/users' => an_instance_of(Hash)
        )
      )
    )
  end
end

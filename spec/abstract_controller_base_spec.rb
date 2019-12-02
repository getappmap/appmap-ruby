require 'rails_spec_helper'

describe 'AbstractControllerBase' do
  before(:all) { @fixture_dir = 'spec/fixtures/rails_users_app' }
  include_context 'Rails app pg database'
  
  around(:each) do |example|
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    cmd = "docker-compose run --rm -e APPMAP=true -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec spec/controllers/users_controller_api_spec.rb:8"
    system cmd, chdir: @fixture_dir or raise 'Failed to run rails_users_app container'

    example.run
  end

  let(:tmpdir) { 'tmp/spec/AbstractControllerBase' }
  let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.json') }

  describe 'testing with rspec' do
    it 'Message fields are recorded in the appmap' do
      expect(File).to exist(appmap_json)
      appmap = JSON.parse(File.read(appmap_json)).to_yaml

      expect(appmap).to include(<<-MESSAGE.strip)
  message:
    login: alice
    password: "[FILTERED]"
      MESSAGE

      expect(appmap).to include(<<-SERVER_REQUEST.strip)
  http_server_request:
    request_method: POST
    path_info: "/api/users"
      SERVER_REQUEST
    end
  end
end

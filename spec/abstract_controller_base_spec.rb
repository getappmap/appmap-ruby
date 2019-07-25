require 'spec_helper'

describe 'AbstractControllerBase' do
  around(:each) do |example|
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    cmd = "docker run --rm -e APPMAP=true -v #{File.absolute_path tmpdir}:/app/tmp appmap-rails_users_app ./bin/rspec spec/controllers/users_controller_spec.rb:8"
    system cmd, chdir: 'spec/fixtures/rails_users_app' or raise 'Failed to run rails_users_app container'

    example.run
  end

  let(:tmpdir) { 'tmp/spec/AbstractControllerBase' }
  let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/UsersController POST users with required parameters creates a user.json') }

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
    path_info: "/users"
      SERVER_REQUEST
    end
  end
end

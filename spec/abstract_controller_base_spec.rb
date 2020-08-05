require 'rails_spec_helper'

describe 'AbstractControllerBase' do
  before(:all) { @fixture_dir = 'spec/fixtures/rails_users_app' }
  include_context 'Rails app pg database'

  around(:each) do |example|
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    cmd = "docker-compose run --rm -e APPMAP=true -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec spec/controllers/users_controller_api_spec.rb:8"
    run_cmd cmd, chdir: @fixture_dir

    example.run
  end

  let(:tmpdir) { 'tmp/spec/AbstractControllerBase' }
  let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.appmap.json') }

  describe 'testing with rspec' do
    it 'inventory file is printed' do
      expect(File).to exist(File.join(tmpdir, 'appmap/rspec/Inventory.appmap.json'))
    end

    it 'message fields are recorded in the appmap' do
      expect(File).to exist(appmap_json)
      appmap = JSON.parse(File.read(appmap_json)).to_yaml

      expect(appmap).to include(<<-MESSAGE.strip)
  message:
  - name: login
    class: String
    value: alice
    object_id:
      MESSAGE

      expect(appmap).to include(<<-MESSAGE.strip)
  - name: password
    class: String
    value: "[FILTERED]"
    object_id:
      MESSAGE

      expect(appmap).to include(<<-SERVER_REQUEST.strip)
  http_server_request:
    request_method: POST
    path_info: "/api/users"
      SERVER_REQUEST
    end

    it 'properly captures method parameters in the appmap' do
      expect(File).to exist(appmap_json)
      appmap = JSON.parse(File.read(appmap_json)).to_yaml

      expect(appmap).to match(<<-CREATE_CALL.strip)
  event: call
  thread_id: .*
  defined_class: Api::UsersController
  method_id: build_user
  path: app/controllers/api/users_controller.rb
  lineno: 23
  static: false
  parameters:
  - name: params
    class: ActiveSupport::HashWithIndifferentAccess
    object_id: .*
    value: '{"login"=>"alice"}'
    kind: req
  receiver:
      CREATE_CALL
    end

    it 'returns a minimal event' do
      expect(File).to exist(appmap_json)
      appmap = JSON.parse(File.read(appmap_json))
      event = appmap['events'].find { |event| event['event'] == 'return' && event['return_value'] }
      expect(event.keys).to eq(%w[id event thread_id parent_id elapsed return_value])
    end
  end
end

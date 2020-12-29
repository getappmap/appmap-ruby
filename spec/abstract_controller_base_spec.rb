require 'rails_spec_helper'

describe 'AbstractControllerBase' do
  shared_examples 'rails version' do |rails_major_version|
    include_context 'Rails app pg database', "spec/fixtures/rails#{rails_major_version}_users_app" do
      def run_spec(spec_name)
        cmd = "docker-compose run --rm -e APPMAP=true -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec #{spec_name}"
        run_cmd cmd, chdir: fixture_dir
      end

      before do
        FileUtils.rm_rf tmpdir
        FileUtils.mkdir_p tmpdir
        run_spec spec_name
      end

      let(:tmpdir) { 'tmp/spec/AbstractControllerBase' }

      describe 'testing with rspec' do
        let(:spec_name) { 'spec/controllers/users_controller_api_spec.rb:8' }
        let(:appmap_json_file) { File.join(tmpdir, 'appmap/rspec/Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.appmap.json') }

        describe 'creating a user' do
          it 'inventory file is printed' do
            expect(File).to exist(File.join(tmpdir, 'appmap/rspec/Inventory.appmap.json'))
          end

          it 'message fields are recorded in the appmap' do
            expect(File).to exist(appmap_json_file)
            appmap = JSON.parse(File.read(appmap_json_file)).to_yaml

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

            expect(appmap).to include(<<-SERVER_RESPONSE.strip)
  http_server_response:
    status: 201
    mime_type: application/json; charset=utf-8
            SERVER_RESPONSE
          end

          it 'properly captures method parameters in the appmap' do
            expect(File).to exist(appmap_json_file)
            appmap = JSON.parse(File.read(appmap_json_file)).to_yaml

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
            expect(File).to exist(appmap_json_file)
            appmap = JSON.parse(File.read(appmap_json_file))
            event = appmap['events'].find { |event| event['event'] == 'return' && event['return_value'] }
            expect(event.keys).to eq(%w[id event thread_id parent_id elapsed return_value])
          end
        end
        describe 'listing users' do
          let(:spec_name) { 'spec/controllers/users_controller_spec.rb:11' }
          let(:appmap_json_file) { File.join(tmpdir, 'appmap/rspec/UsersController_GET_users_lists_the_users.appmap.json') }
          it 'records and labels view rendering' do
            expect(File).to exist(appmap_json_file)
            appmap = JSON.parse(File.read(appmap_json_file)).to_yaml

            expect(appmap).to match(<<-VIEW_CALL.strip)
  event: call
  thread_id: .*
  defined_class: ActionView::Renderer
  method_id: render
  path: .*
  lineno: .*
  static: false
            VIEW_CALL

            expect(appmap).to match(<<-VIEW_LABEL.strip)
        labels:
        - view
            VIEW_LABEL
          end
        end
      end
    end
  end

  it_behaves_like 'rails version', '5'
  it_behaves_like 'rails version', '6'
end

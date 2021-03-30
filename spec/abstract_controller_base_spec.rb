require 'rails_spec_helper'

describe 'AbstractControllerBase' do
  %w[5 6].each do |rails_major_version| # rubocop:disable Metrics/BlockLength
    context "in Rails #{rails_major_version}" do
      include_context 'Rails app pg database', "spec/fixtures/rails#{rails_major_version}_users_app"
      def run_spec(spec_name)
        FileUtils.rm_rf tmpdir
        FileUtils.mkdir_p tmpdir
        cmd = <<~CMD.gsub "\n", ' '
          docker-compose run --rm -e RAILS_ENV=test -e APPMAP=true
          -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec #{spec_name}
        CMD
        run_cmd cmd, chdir: fixture_dir
      end

      def tmpdir
        'tmp/spec/AbstractControllerBase'
      end

      let(:appmap) { JSON.parse File.read File.join tmpdir, 'appmap/rspec', appmap_json_file }
      let(:events) { appmap['events'] }

      describe 'testing with rspec' do
        describe 'creating a user' do
          before(:all) { run_spec 'spec/controllers/users_controller_api_spec.rb:8' }
          let(:appmap_json_file) do
            'Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.appmap.json'
          end

          it 'inventory file is printed' do
            expect(File).to exist(File.join(tmpdir, 'appmap/rspec/Inventory.appmap.json'))
          end

          it 'message fields are recorded in the appmap' do
            expect(events).to include(
              hash_including(
                'http_server_request' => hash_including(
                  'request_method' => 'POST',
                  'normalized_path_info' => '/api/users(.:format)',
                  'path_info' => '/api/users'
                ),
                'message' => include(
                  hash_including(
                    'name' => 'login',
                    'class' => 'String',
                    'value' => 'alice',
                    'object_id' => Integer
                  ),
                  hash_including(
                    'name' => 'password',
                    'class' => 'String',
                    'value' => '[FILTERED]',
                    'object_id' => Integer
                  )
                )
              ),
              hash_including(
                'http_server_response' => {
                  'status' => 201,
                  'mime_type' => 'application/json; charset=utf-8'
                }
              )
            )
          end

          context 'with an object-style message' do
            # TODO
            it 'message properties are recorded in the appmap'
          end

          it 'properly captures method parameters in the appmap' do
            expect(events).to include hash_including(
              'event' => 'call',
              'thread_id' => Integer,
              'defined_class' => 'Api::UsersController',
              'method_id' => 'build_user',
              'path' => 'app/controllers/api/users_controller.rb',
              'lineno' => Integer,
              'static' => false,
              'parameters' => include(
                'name' => 'params',
                'class' => 'ActiveSupport::HashWithIndifferentAccess',
                'object_id' => Integer,
                'value' => '{"login"=>"alice"}',
                'kind' => 'req'
              ),
              'receiver' => anything
            )
          end

          it 'returns a minimal event' do
            expect(events).to include hash_including(
              'event' => 'return',
              'return_value' => Hash,
              'id' => Integer,
              'thread_id' => Integer,
              'parent_id' => Integer,
              'elapsed' => Numeric
            )
          end
        end

        describe 'showing a user' do
          before(:all) { run_spec 'spec/controllers/users_controller_spec.rb:22' }
          let(:appmap_json_file) do
            'UsersController_GET_users_login_shows_the_user.appmap.json'
          end

          it 'records the normalized path info' do
            expect(events).to include(
              hash_including(
                'http_server_request' => {
                  'request_method' => 'GET',
                  'path_info' => '/users/alice',
                  'normalized_path_info' => '/users/:id(.:format)'
                }
              )
            )
          end
        end

        describe 'listing users' do
          before(:all) { run_spec 'spec/controllers/users_controller_spec.rb:11' }
          let(:appmap_json_file) { 'UsersController_GET_users_lists_the_users.appmap.json' }

          it 'records and labels view rendering' do
            expect(events).to include hash_including(
              'event' => 'call',
              'thread_id' => Numeric,
              'defined_class' => 'ActionView::Renderer',
              'method_id' => 'render',
              'path' => String,
              'lineno' => Integer,
              'static' => false
            )

            expect(appmap['classMap']).to include hash_including(
              'name' => 'action_view',
              'children' => include(hash_including(
                'name' => 'ActionView',
                'children' => include(hash_including(
                  'name' => 'Renderer',
                  'children' => include(hash_including(
                    'name' => 'render',
                    'labels' => ['mvc.view']
                  ))
                ))
              ))
            )
          end
        end
      end
    end
  end
end

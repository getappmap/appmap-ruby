require 'rails_spec_helper'

describe 'Rails' do
  %w[5 6].each do |rails_major_version| # rubocop:disable Metrics/BlockLength
    context "#{rails_major_version}" do
      include_context 'Rails app pg database', "spec/fixtures/rails#{rails_major_version}_users_app" unless use_existing_data?

      def run_spec(spec_name)
        cmd = <<~CMD.gsub "\n", ' '
          docker-compose run --rm -e RAILS_ENV=test -e APPMAP=true
          -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec #{spec_name}
        CMD
        run_cmd cmd, chdir: fixture_dir
      end

      def tmpdir
        'tmp/spec/AbstractControllerBase'
      end

      unless use_existing_data?
        before(:all) do
          FileUtils.rm_rf tmpdir
          FileUtils.mkdir_p tmpdir
          run_spec 'spec/controllers/users_controller_spec.rb'
          run_spec 'spec/controllers/users_controller_api_spec.rb'
        end
      end

      let(:appmap) { JSON.parse File.read File.join tmpdir, 'appmap/rspec', appmap_json_file }
      let(:appmap_json_path) { File.join(tmpdir, 'appmap/rspec', appmap_json_file) }
      let(:appmap) { JSON.parse File.read(appmap_json_path) }
      let(:events) { appmap['events'] }

      describe 'an API route' do
        describe 'creating an object' do
          let(:appmap_json_file) do
            'Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.appmap.json'
          end

          it 'http_server_request is recorded in the appmap' do
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
              )
            )
          end

          it 'http_server_response is recorded in the appmap' do
            expect(events).to include(
              hash_including(
                'http_server_response' => hash_including(
                  'status_code' => 201,
                  'mime_type' => 'application/json; charset=utf-8',
                )
              )
            )
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

          context 'with an object-style message' do
            let(:appmap_json_file) { 'Api_UsersController_POST_api_users_with_required_parameters_with_object-style_parameters_creates_a_user.appmap.json' }

            it 'message properties are recorded in the appmap' do
              expect(events).to include(
                hash_including(
                  'message' => include(
                    hash_including(
                      'name' => 'user',
                      'properties' => [
                        { 'name' => 'login', 'class' => 'String' },
                        { 'name' => 'password', 'class' => 'String' }
                      ]
                    )
                  )
                )
              )    
            end
          end
        end

        describe 'listing objects' do
          context 'with a custom header' do
            let(:appmap_json_file) { 'Api_UsersController_GET_api_users_with_a_custom_header_lists_the_users.appmap.json' }

            it 'custom header is recorded in the appmap' do
              expect(events).to include(
                hash_including(
                  'http_server_request' => hash_including(
                    'headers' => hash_including('X-Sandwich' => 'turkey')
                  )
                )
              )
            end
          end
        end
      end

      describe 'a UI route' do
        describe 'rendering a page' do
          let(:appmap_json_file) do
            'UsersController_GET_users_login_shows_the_user.appmap.json'
          end

          it 'records the normalized path info' do
            expect(events).to include(
              hash_including(
                'http_server_request' => {
                  'request_method' => 'GET',
                  'path_info' => '/users/alice',
                  'normalized_path_info' => '/users/:id(.:format)',
                  'headers' => {
                    'Host' => 'test.host', 
                    'User-Agent' => 'Rails Testing'
                  }
                }
              )
            )
          end

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
              'name' => 'actionview',
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

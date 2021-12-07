require 'rails_spec_helper'

def default_rails_versions
  ruby_2? ? [ 5, 6 ] : [ 6 ]
end

# Rails5 doesn't work with Ruby 3.x
RailsVersions = ENV['RAILS_VERSIONS'] || default_rails_versions

describe 'Rails' do
  RailsVersions.each do |rails_major_version| # rubocop:disable Metrics/BlockLength
    context "#{rails_major_version}" do
      include_context 'Rails app pg database', "spec/fixtures/rails#{rails_major_version}_users_app" unless use_existing_data?
      include_context 'rails integration test setup'

      def run_spec(spec_name)
        cmd = <<~CMD.gsub "\n", ' '
          docker-compose run --rm -e RAILS_ENV=test -e APPMAP=true
          -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec #{spec_name}
        CMD
        run_cmd cmd, chdir: fixture_dir
      end

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
                  'normalized_path_info' => '/api/users',
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
                  'headers' => hash_including('Content-Type' => 'application/json; charset=utf-8'),
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

          it 'captures log events' do
            expect(events).to include hash_including(
              'event' => 'call',
              'defined_class' => 'Logger::LogDevice',
              'method_id' => 'write',
              'static' => false
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
        describe 'rendering a page using a template file' do
          let(:appmap_json_file) do
            'UsersController_GET_users_lists_the_users.appmap.json'
          end

          it 'records the template file' do
            expect(events).to include hash_including(
              'event' => 'call',
              'defined_class' => 'app_views_users_index_html_haml',
              'method_id' => 'render',
              'path' => 'app/views/users/index.html.haml'
            )

            expect(appmap['classMap']).to include hash_including(
              'name' => 'app',
              'children' => include(hash_including(
                'name' => 'views',
                'children' => include(hash_including(
                  'name' => 'app_views_users_index_html_haml',
                  'children' => include(hash_including(
                    'name' => 'render',
                    'type' => 'function',
                    'location' => 'app/views/users/index.html.haml',
                    'static' => true,
                    'labels' => [ 'mvc.template' ]
                  )))))))
            expect(appmap['classMap']).to include hash_including(
              'name' => 'app',
              'children' => include(hash_including(
                'name' => 'views',
                'children' => include(hash_including(
                  'name' => 'app_views_layouts_application_html_haml',
                  'children' => include(hash_including(
                    'name' => 'render',
                    'type' => 'function',
                    'location' => 'app/views/layouts/application.html.haml',
                    'static' => true,
                    'labels' => [ 'mvc.template' ]
                  )))))))
          end
        end

        describe 'rendering a page using a text template' do
          let(:appmap_json_file) do
            'UsersController_GET_users_login_shows_the_user.appmap.json'
          end

          it 'records the normalized path info' do
            expect(events).to include(
              hash_including(
                'http_server_request' => {
                  'request_method' => 'GET',
                  'path_info' => '/users/alice',
                  'normalized_path_info' => '/users/{id}',
                  'headers' => {
                    'Host' => 'test.host', 
                    'User-Agent' => 'Rails Testing'
                  }
                }
              )
            )
          end

          it 'ignores the text template' do
            expect(events).to_not include hash_including(
              'event' => 'call',
              'method_id' => 'render',
              'render_template' => anything
            )

            expect(appmap['classMap']).to_not include hash_including(
              'name' => 'views',
              'children' => include(hash_including(
                'name' => 'ViewTemplate',
                'children' => include(hash_including(
                  'name' => 'render',
                  'type' => 'function',
                  'location' => 'text template'
                ))
              ))
            )
          end

          it 'records and labels view rendering' do
            expect(events).to include hash_including(
              'event' => 'call',
              'thread_id' => Numeric,
              'defined_class' => 'inline_template',
              'method_id' => 'render'
            )
  
            expect(appmap['classMap']).to include hash_including(
              'name' => 'actionview',
              'children' => include(hash_including(
                'name' => 'ActionView',
                'children' => include(hash_including(
                  # Rails 6/5 difference
                  'name' => /^(Template)?Renderer$/,
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

  describe 'with default appmap.yml' do
    include_context 'Rails app pg database', "spec/fixtures/rails6_users_app" unless use_existing_data?
    include_context 'rails integration test setup'

    def run_spec(spec_name)
      cmd = <<~CMD.gsub "\n", ' '
        docker-compose run --rm -e RAILS_ENV=test -e APPMAP=true -e APPMAP_CONFIG_FILE=no/such/file
        -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec #{spec_name}
      CMD
      run_cmd cmd, chdir: fixture_dir
    end

    let(:appmap_json_file) do
      'Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.appmap.json'
    end

    it 'http_server_request is recorded' do
      expect(events).to include(
        hash_including(
          'http_server_request' => hash_including(
            'request_method' => 'POST',
            'path_info' => '/api/users'
          )
        )
      )
    end

    it 'controller method is recorded' do
      expect(events).to include hash_including(
        'defined_class' => 'Api::UsersController',
        'method_id' => 'build_user',
        'path' => 'app/controllers/api/users_controller.rb',
      )
    end
  end
end

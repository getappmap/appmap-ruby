require 'rails_spec_helper'

describe 'SQL events' do
  include_context 'Rails app pg database', 'spec/fixtures/rails6_users_app' do
    before(:all) { @app.prepare_db }

    before do
      FileUtils.rm_rf tmpdir
      app.run_cmd \
        "./bin/rspec spec/controllers/users_controller_api_spec.rb:#{test_line_number}",
        'ORM_MODULE' => orm_module,
        'RAILS_ENV' => 'test',
        'APPMAP' => 'true'
    end

    let(:tmpdir) { app.tmpdir }

    describe 'fields' do
      let(:test_line_number) { 8 }
      let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.appmap.json') }
      let(:orm_module) { 'sequel' }
      let(:appmap) { JSON.parse(File.read(appmap_json)) }
      describe 'on a call event' do
        let(:event) do
          appmap['events'].find do |event|
            event['event'] == 'call' &&
              event.keys.include?('sql_query')
          end
        end
        it 'do not include function-only fields' do
          expect(event.keys).to_not include('defined_class')
          expect(event.keys).to_not include('method_id')
          expect(event.keys).to_not include('path')
          expect(event.keys).to_not include('lineno')
        end
      end
    end

    describe 'in a Rails app' do
      let(:appmap) { JSON.parse(File.read(appmap_json)).to_yaml }
      context 'while creating a new record' do
        let(:test_line_number) { 8 }
        let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.appmap.json') }

        context 'using Sequel ORM' do
          let(:orm_module) { 'sequel' }
          it 'detects the sql INSERT' do
            expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: INSERT INTO "users" ("login") VALUES ('alice') RETURNING *
            SQL_QUERY
          end
        end
        context 'using ActiveRecord ORM' do
          let(:orm_module) { 'activerecord' }
          it 'detects the sql INSERT' do
            expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: INSERT INTO "users" ("login") VALUES ($1) RETURNING "id"
            SQL_QUERY
          end
        end
      end

      context 'while listing records' do
        let(:test_line_number) { 29 }
        let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api_UsersController_GET_api_users_lists_the_users.appmap.json') }

        context 'using Sequel ORM' do
          let(:orm_module) { 'sequel' }
          it 'detects the sql SELECT' do
            expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: SELECT * FROM "users"
            SQL_QUERY

            expect(appmap).to include('sql:')
          end
        end
        context 'using ActiveRecord ORM' do
          let(:orm_module) { 'activerecord' }
          it 'detects the sql SELECT' do
            expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: SELECT "users".* FROM "users"
            SQL_QUERY
          end
        end
      end
    end
  end
end

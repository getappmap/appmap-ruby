require 'rails_spec_helper'

describe 'Record SQL queries in a Rails app' do
  include_examples 'Rails app pg database'

  around(:each) do |example|
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    cmd = "docker-compose run --rm -e ORM_MODULE=#{orm_module} -e APPMAP=true -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec spec/controllers/users_controller_api_spec.rb:#{test_line_number}"
    system cmd, chdir: 'spec/fixtures/rails_users_app' or raise 'Failed to run rails_users_app container'

    example.run
  end

  let(:tmpdir) { "tmp/spec/record_sql_rails_pg_spec" }
  let(:appmap) { JSON.parse(File.read(appmap_json)).to_yaml }

  context 'while creating a new record' do
    let(:test_line_number) { 8 }
    let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api::UsersController POST _api_users with required parameters creates a user.json') }

    context 'using Sequel ORM' do
      let(:orm_module) { 'sequel' }
      it 'detects the sql INSERT' do
        expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: INSERT INTO "users" ("login") VALUES ('alice') RETURNING *
        SQL_QUERY
        # INSERT queries are not explained
        expect(appmap).to_not include('explain_sql:')
      end
    end
    context 'using ActiveRecord ORM' do
      let(:orm_module) { 'activerecord' }
      it 'detects the sql INSERT' do
        expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: INSERT INTO "users" ("login") VALUES ($1) RETURNING "id"
        SQL_QUERY
        # INSERT queries are not explained
        expect(appmap).to_not include('explain_sql:')
      end
    end
  end

  context 'while listing records' do
    let(:test_line_number) { 23 }
    let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api::UsersController GET _api_users lists the users.json') }

    context 'using Sequel ORM' do
      let(:orm_module) { 'sequel' }
      it 'detects the sql SELECT and computes explain_sql' do
        expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: SELECT * FROM "users"
        SQL_QUERY

        expect(appmap).to include('sql:')
        expect(appmap).to include('explain_sql:')
      end
    end
    context 'using ActiveRecord ORM' do
      let(:orm_module) { 'activerecord' }
      it 'detects the sql SELECT and computes explain_sql' do
        expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: SELECT "users".* FROM "users"
        SQL_QUERY
        expect(appmap).to include('explain_sql:')
      end
    end
  end
end

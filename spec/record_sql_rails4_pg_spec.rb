require 'rails_spec_helper'

describe 'Record SQL queries in a Rails4 app' do
  before(:all) { @fixture_dir = 'spec/fixtures/rails4_users_app' }
  include_context 'Rails app pg database'
  
  around(:each) do |example|
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    cmd = "docker-compose run --rm -e ORM_MODULE=#{orm_module} -e APPMAP=true -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec -f doc -b spec/controllers/users_controller_api_spec.rb:#{test_line_number}"
    system cmd, chdir: @fixture_dir or raise 'Failed to run rails_users_app container'

    example.run
  end

  let(:tmpdir) { "tmp/spec/record_sql_rails_pg_spec" }
  let(:appmap) { JSON.parse(File.read(appmap_json)).to_yaml }

  context 'when running specs' do
    let(:test_line_number) { 31 }
    let(:orm_module) { 'activerecord' }

    it { is_expected.to be }
  end
  
  context 'while creating a new record' do
    let(:test_line_number) { 8 }
    let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api_UsersController_POST_api_users_with_required_parameters_creates_a_user.appmap.json') }

    xcontext 'using Sequel ORM' do
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
    sql: INSERT INTO "users" ("login", "created_at", "updated_at") VALUES ($1, $2,
      $3) RETURNING "id"
        SQL_QUERY
      end
    end
  end

  context 'while listing records' do
    let(:test_line_number) { 23 }
    let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api_UsersController_GET_api_users_lists_the_users.appmap.json') }

    xcontext 'using Sequel ORM' do
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

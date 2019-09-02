require 'rails_spec_helper'

describe 'Record SQL queries in a Rails app' do
  include_examples 'Rails app pg database'

  around(:each) do |example|
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    cmd = "docker-compose run --rm -e ORM_MODULE=#{orm_module} -e APPMAP=true -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec spec/controllers/users_controller_api_spec.rb:8"
    system cmd, chdir: 'spec/fixtures/rails_users_app' or raise 'Failed to run rails_users_app container'

    example.run
  end

  let(:tmpdir) { "tmp/spec/record_sql_#{orm_module}_rails_pg" }
  let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api::UsersController POST _api_users with required parameters creates a user.json') }
  let(:appmap) { JSON.parse(File.read(appmap_json)).to_yaml }

  describe 'using Sequel ORM' do
    let(:orm_module) { 'sequel' }
    it 'injects the sql_query data' do
      expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: INSERT INTO "users" ("login") VALUES ('alice') RETURNING *
      SQL_QUERY
    end
  end
  describe 'using ActiveRecord ORM' do
    let(:orm_module) { 'activerecord' }
    it 'injects the sql_query data' do
      expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: INSERT INTO "users" ("login") VALUES ('alice') RETURNING *
      SQL_QUERY
    end
  end
end

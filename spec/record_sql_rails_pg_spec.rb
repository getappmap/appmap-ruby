require 'rails_spec_helper'

describe 'Record SQL in a Rails with Postgres' do
  include_examples 'Rails app pg database'

  around(:each) do |example|
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    cmd = "docker-compose run --rm -e APPMAP=true -v #{File.absolute_path tmpdir}:/app/tmp app ./bin/rspec spec/controllers/users_controller_api_spec.rb:8"
    system cmd, chdir: 'spec/fixtures/rails_users_app' or raise 'Failed to run rails_users_app container'

    example.run
  end

  let(:tmpdir) { 'tmp/spec/record_sql_rails_pg' }
  let(:appmap_json) { File.join(tmpdir, 'appmap/rspec/Api::UsersController POST _api_users with required parameters creates a user.json') }

  describe 'testing with rspec' do
    it 'SQL query fields are recorded in the appmap' do
      expect(File).to exist(appmap_json)
      appmap = JSON.parse(File.read(appmap_json)).to_yaml

      expect(appmap).to include(<<-SQL_QUERY.strip)
  sql_query:
    sql: INSERT INTO "users" ("login") VALUES ('alice') RETURNING *
      SQL_QUERY
    end
  end
end

require 'rails_spec_helper'

describe 'SQL events' do
  rails_versions.each do |rails_version|
    context "Rails #{rails_version}" do
      include_context 'rails app', rails_version

      def self.check_queries(cases)
        cases.each do |test_case, query|
          context "in #{test_case}" do
            let(:test_case) { test_case }
            it "captures #{query}" do
              expect(sql_events).to include sql_query query
            end
          end
        end
      end

      context 'with Sequel' do
        before(:context) { run_specs 'sequel' }

        check_queries(
          'Api_UsersController_POST_api_users_with_required_parameters_creates_a_user' =>
            %(INSERT INTO "users" ("login") VALUES ('alice') RETURNING *),
          'Api_UsersController_GET_api_users_lists_the_users' => %(SELECT * FROM "users")
        )
      end

      context 'with ActiveRecord' do
        before(:context) { run_specs 'activerecord' }

        expected_query = if rails_version == 7
                           %(INSERT INTO "users" ("login", "password_digest") VALUES ($1, $2) RETURNING "id")
                         else
                           %(INSERT INTO "users" ("login") VALUES ($1) RETURNING "id")
                         end

        check_queries(
          'Api_UsersController_POST_api_users_with_required_parameters_creates_a_user' => expected_query,
          'Api_UsersController_GET_api_users_lists_the_users' => %(SELECT "users".* FROM "users")
        )
      end

      def run_specs(orm_module)
        @app.prepare_db
        @app.run_cmd \
          './bin/rspec spec/controllers/users_controller_api_spec.rb:8 spec/controllers/users_controller_api_spec.rb:29',
          'ORM_MODULE' => orm_module,
          'RAILS_ENV' => 'test',
          'APPMAP' => 'true'
      end

      let(:appmap_json) { File.join tmpdir, "appmap/rspec/#{test_case}.appmap.json" }
      let(:appmap) { JSON.parse(File.read(appmap_json)) }
      let(:tmpdir) { app.tmpdir }
      let(:sql_events) { appmap['events'].select { |ev| ev.include? 'sql_query' } }

      RSpec::Matchers.define_negated_matcher :not_include, :include
      def sql_query(query)
        (include('sql_query' => (include 'sql' => query)))
          .and(not_include('defined_class'))
          .and(not_include('method_id'))
          .and(not_include('path'))
          .and(not_include('lineno'))
      end
    end
  end
end

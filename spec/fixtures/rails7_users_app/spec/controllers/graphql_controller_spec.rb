require 'rails_helper'
require 'rack/test'

RSpec.describe GraphqlController, type: :controller do
  describe 'POST /graphql' do
    let(:user_logins) { %w[alice bob charles] }

    before do
      user_logins.each do |login|
        User.create(login: login)
      end
    end

    # We want to test the connection pool stats after a handful of requests
    # to verify that the connection pool is not leaking connections.
    # @see https://github.com/getappmap/appmap-ruby/pull/353
    context "when 10 requests are made" do

      it 'returns the users and connection stat' do
        graphql_query = "query { users { id, login } }"

        puts "RAILS VERSION: #{Rails.version}"

        10.times do
          post :execute, params: { query: graphql_query }
          expect(response.status).to eq(200)

          results = JSON.parse(response.body)

          puts "RESULTS: #{results}"

          users = results["data"]["users"]
          expect(users.map { |r| r["login"] }.sort).to eq(user_logins)

          stats = results["data"]["connection_pool_stats"].symbolize_keys
          expect(stats[:size]).to eq(5)
          expect(stats[:connections]).to eq(1)
          expect(stats[:dead]).to eq(0)
          expect(stats[:idle]).to eq(0)
          expect(stats[:waiting]).to eq(0)
        end
      end
    end
  end
end

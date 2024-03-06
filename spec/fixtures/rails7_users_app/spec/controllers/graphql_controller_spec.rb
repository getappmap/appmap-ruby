require 'rails_helper'
require 'rack/test'

RSpec.describe GraphqlController, type: :controller do
  describe 'POST /graphql' do
    let(:user_logins) { %w[alice bob charles] }

    before do
      user_logins.each do |login|
        user = User.create!(login: login)
        puts "Created user: #{user.login} (#{user.id})"
      end
    end

    def assert_thread_based_connection_pool_stats(stats)
      puts "STATS (thread): #{stats}"

      expect(stats[:size]).to eq(5)
      expect(stats[:connections]).to eq(1)
      expect(stats[:dead]).to eq(0)
      expect(stats[:idle]).to eq(0)
      expect(stats[:waiting]).to eq(0)
    end

    def assert_fiber_based_connection_pool_stats(stats)
      puts "STATS (fiber): #{stats}"

      expect(stats[:size]).to eq(5)
      expect(stats[:connections]).to eq(1)
      expect(stats[:dead]).to eq(0)
      expect(stats[:idle]).to eq(0)
      expect(stats[:waiting]).to eq(0)
    end

    # We want to test the connection pool stats after a handful of requests
    # to verify that the connection pool is not leaking connections.
    # @see https://github.com/getappmap/appmap-ruby/pull/353
    context "when 10 requests are made" do

      it 'returns the users and connection stat' do

        6.times do # total connection pool size is 5
          post :execute, params: { query: "query { users { id, login } }" }
          expect(response.status).to eq(200)

          results = JSON.parse(response.body)

          puts "RESULTS: #{results}"

          users = results["data"]["users"]
          expect(users.map { |r| r["login"] }.sort).to eq(user_logins)

          stats = results["data"]["connection_pool_stats"].symbolize_keys

          if Rails.application.config.active_support.isolation_level == :fiber
            assert_fiber_based_connection_pool_stats(stats)
          else
            assert_thread_based_connection_pool_stats(stats)
          end
        end
      end
    end
  end
end

require "rails_helper"
require "rack/test"

RSpec.describe GraphqlController, type: :controller do
  let(:isolation_level) { nil }

  before do
    User.create(login: "alice")
    User.create(login: "bob")
    User.create(login: "charles")

    @previous_isolation_level = ActiveSupport::IsolatedExecutionState.isolation_level
    ActiveSupport::IsolatedExecutionState.isolation_level = isolation_level
  end

  after do
    ActiveSupport::IsolatedExecutionState.isolation_level = @previous_isolation_level
  end

  context "with thread-based connection pool" do
    let(:isolation_level) { :thread }

    it "returns the users without leaking the connection pool 6 times" do
      6.times do |i|
        post :execute, params: { query: "query { users { id, login } }" }
        expect(response.status).to eq(200)

        results = JSON.parse(response.body)

        users = results["data"]["users"]
        expect(users.map { |r| r["login"] }.sort).to eq(%w[alice bob charles])

        stats = results["data"]["connection_pool_stats"].symbolize_keys
        expect(stats[:size]).to eq(5)
        expect(stats[:connections]).to eq(1)
        expect(stats[:dead]).to eq(0)
        expect(stats[:idle]).to eq(0)
        expect(stats[:waiting]).to eq(0)
      end
    end
  end

  context "with fiber-based connection pool" do
    let(:isolation_level) { :fiber }

    it "returns the users without leaking the connection pool 6 times" do
      6.times do |i|
        post :execute, params: { query: "query { users { id, login } }" }
        expect(response.status).to eq(200)

        results = JSON.parse(response.body)

        users = results["data"]["users"]
        expect(users.map { |r| r["login"] }.sort).to eq(%w[alice bob charles])

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

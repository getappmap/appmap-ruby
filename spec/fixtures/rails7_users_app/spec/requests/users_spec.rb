require 'swagger_helper'
require 'appmap/rswag'

describe 'Users' do
  path '/api/users' do
    post 'Creates a user' do
      consumes 'application/json'
      parameter name: :user, in: :body, schema: {
        type: :object,
        properties: {
          login: { type: :string },
          password: { type: :string }
        },
        required: %w[login password]
      }
      response 201, 'user created' do
        let(:user) { { login: 'alice', password: 'foobar' } }
        run_test!
      end
    end
  end
end

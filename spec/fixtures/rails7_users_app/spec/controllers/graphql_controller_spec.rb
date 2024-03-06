require 'rails_helper'
require 'rack/test'

RSpec.describe GraphqlController, type: :controller do
  describe 'POST /graphql?query={users{id,login}}' do
    it 'returns the users' do
      graphql_query = <<~GRAPHQL
        {
          users {
            id
            login
          }
        }
      GRAPHQL

      post :graphql, params: { query: graphql_query }
      expect(response.status).to eq(200)
      require "pry"
      binding.pry
    end
  end
end

require 'rails_helper'
require 'rack/test'
require 'appmap/rspec'

RSpec.describe UsersController, type: :controller, appmap: true do
  describe 'POST users' do
    describe 'with required parameters' do
      it 'creates a user' do
        post :create, params: { login: 'alice', password: 'foobar' }
        expect(response.status).to eq(201)
      end
    end
    describe 'with a missing parameter' do
      it 'reports error 422' do
        post :create, params: { login: 'alice' }
        expect(response.status).to eq(422)
      end
    end
  end
end

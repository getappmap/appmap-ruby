require 'rails_helper'
require 'rack/test'

RSpec.describe Api::UsersController, feature_group: 'Users', type: :controller, appmap: true do
  describe 'POST /api/users', feature: 'Create a user' do
    describe 'with required parameters' do
      it 'creates a user' do
        post :create, params: { login: 'alice', password: 'foobar' }
        expect(response.status).to eq(201)
      end
    end
    describe 'with a missing parameter' do
      it 'reports error 422' do
        post :create, params: {}
        expect(response.status).to eq(422)
      end
    end
  end
  describe 'GET /api/users', feature: 'List users' do
    before do
      post :create, params: { login: 'alice' }
    end
    it 'lists the users' do
      get :index, params: {}
      users = JSON.parse(response.body)
      expect(users.map { |r| r['login'] }).to include('alice')
    end
  end
end

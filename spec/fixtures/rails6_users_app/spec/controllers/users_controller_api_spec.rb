require 'rails_helper'
require 'rack/test'

RSpec.describe Api::UsersController, type: :controller do
  describe 'POST /api/users' do
    describe 'with required parameters' do
      it 'creates a user' do
        post :create, params: { login: 'alice', password: 'foobar' }
        expect(response.status).to eq(201)
      end
      describe 'with object-style parameters' do
        it 'creates a user' do
          post :create, params: { user: { login: 'alice', password: 'foobar' } }
          expect(response.status).to eq(201)
        end
      end
    end
    describe 'with a missing parameter' do
      it 'reports error 422' do
        post :create, params: {}
        expect(response.status).to eq(422)
      end
    end
  end
  describe 'GET /api/users' do
    before do
      post :create, params: { login: 'alice' }
    end
    it 'lists the users' do
      get :index, params: {}
      users = JSON.parse(response.body)
      expect(users.map { |r| r['login'] }).to include('alice')
    end
    describe 'with a custom header' do
      it 'lists the users' do
        request.headers['X-Sandwich'] = 'turkey'
        get :index, params: {}
        expect(response.status).to eq(200)
      end
    end
  end
end

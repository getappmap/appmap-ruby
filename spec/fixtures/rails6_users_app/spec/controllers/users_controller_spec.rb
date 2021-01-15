require 'rails_helper'
require 'rack/test'

RSpec.describe UsersController, type: :controller do
  render_views

  describe 'GET /users', feature: 'Show all users' do
    before do
      User.create login: 'alice'
    end
    it 'lists the users' do
      get :index
      expect(response).to be_ok
    end
  end

  describe 'GET /users/:login', feature: 'Show a user' do
    before do
      User.create login: 'alice'
    end

    it 'shows the user' do
      get :show, params: { id: 'alice' }
      expect(response).to be_ok
    end
  end
end

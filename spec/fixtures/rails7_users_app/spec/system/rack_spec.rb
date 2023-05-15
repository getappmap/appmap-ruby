# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Rack stack', type: :system do
  before do
    driven_by :rack_test
  end

  it 'changes the response on the index to 422' do
    visit '/users?hi'
    expect(page.status_code).to equal 422
  end

  it 'can serve sprocket assets' do
    visit '/assets/application.css'
    expect(page.status_code).to equal 200
  end
end

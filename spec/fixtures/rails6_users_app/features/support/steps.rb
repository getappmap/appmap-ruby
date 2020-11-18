# frozen_string_literal: true

When 'I create a user' do
  @response = post '/api/users', login: 'alice'
end

Then(/the response status should be (\d+)/) do |status|
  expect(@response.status).to eq(status.to_i)
end

When 'I list the users' do
  @response = get '/api/users'
  @users = JSON.parse(@response.body)
end

Then 'the response should include the user' do
  expect(@users.map { |u| u['login'] }).to include('alice')
end

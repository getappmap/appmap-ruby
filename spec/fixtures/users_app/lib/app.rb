require 'rack/app'
require 'json'

class App < Rack::App
  USERS = Hash.new

  class CodedError < StandardError
    attr_reader :code

    def initialize(code)
      @code = code
    end
  end

  get '/health' do
    response.status = 204
  end

  post '/users' do
    params = JSON.parse(request.body.read)
    user_id = params['login']
    password = params['password']
    halt 422 unless user_id && password
    USERS[user_id] = params
    response.headers['location'] = "/users/#{user_id}"
    response.status = 201
  end

  post '/users/:login/authenticate' do
    halt 422 unless (user_id = params['login'])
    halt 404 unless (user = USERS[user_id])
    password = request.body.read.strip
    response.status = user['password'] == password ? 200 : 401
    nil
  end

  def halt(code)
    raise CodedError, code
  end

  error CodedError do |ex|
    response.status = ex.code
  end
end

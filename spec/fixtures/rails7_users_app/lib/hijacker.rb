# frozen_string_literal: true

# Rack middleware that changes the response
# code to 422 if the query string is "hi"
class Hijacker
  def initialize(app)
    @app = app
  end

  def call(env)
    @app.call(env).tap do |response|
      response[0] = 422 if env['QUERY_STRING'] == 'hi'
    end
  end
end

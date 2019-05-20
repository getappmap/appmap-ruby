# Middleware which is inserted so that each request can be effectively captured
# in the AppMap.
module AppMap
  module Rack
    class Trace
      def initialize(app)
        @app = app
      end

      def call(env)
        req = ::Rack::Request.new(env)
        request req.request_method, req.path, env
      end

      def request(request_method, path, env)
        @app.call(env)
      end
    end
  end
end

require 'appmap/inject/request_injector'

module AppMap
  module Middleware
    class Injector
      def initialize(app)
        @app = app
        @injector = AppMap::Inject::RequestInjector.load
      end

      def call(env)
        return @app.call(env) unless @injector

        req = Rack::Request.new(env)
        @injector.inject(req)

        @app.call(env)
      end
    end
  end
end

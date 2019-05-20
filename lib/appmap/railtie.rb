module AppMap
  class Railtie < Rails::Railtie
    initializer "appmap.add_middleware" do |app|
      require 'appmap/rack/trace'
      $stderr.puts "Loading AppMap::Rack::Trace middleware"
      app.middleware.insert_before(Rails::Rack::Logger, AppMap::Rack::Trace)
    end
  end
end

require 'appmap/middleware/remote_recording'
Rails.application.config.middleware.insert_after Rails::Rack::Logger, AppMap::Middleware::RemoteRecording \
  unless Rails.env.test?

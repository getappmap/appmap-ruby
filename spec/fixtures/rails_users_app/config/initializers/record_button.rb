require 'appmap/middleware/record_button'
Rails.application.config.middleware.insert_after Rails::Rack::Logger, AppMap::Middleware::RecordButton \
  unless Rails.env.test?

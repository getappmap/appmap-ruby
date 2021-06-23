# frozen_string_literal: true

module AppMap
  # Railtie connects the AppMap recorder to Rails-specific features.
  class Railtie < ::Rails::Railtie
    initializer 'appmap.remote_recording' do
      require 'appmap/middleware/remote_recording'
      Rails.application.config.middleware.insert_before \
        ActionDispatch::Executor,
        AppMap::Middleware::RemoteRecording
    end

    # appmap.subscribe subscribes to ActiveSupport Notifications so that they can be recorded as
    # AppMap events.
    initializer 'appmap.subscribe' do |_| # params: app
      require 'appmap/handler/rails/sql_handler'
      require 'appmap/handler/rails/request_handler'
      ActiveSupport::Notifications.subscribe 'sql.sequel', AppMap::Handler::Rails::SQLHandler.new
      ActiveSupport::Notifications.subscribe 'sql.active_record', AppMap::Handler::Rails::SQLHandler.new

      AppMap::Handler::Rails::RequestHandler::HookMethod.new.activate
    end
  end
end if ENV['APPMAP'] == 'true'

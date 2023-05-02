# frozen_string_literal: true

module AppMap
  # Railtie connects the AppMap recorder to Rails-specific features.
  class Railtie < ::Rails::Railtie
    initializer 'appmap.remote_recording' do
      # Indicate early in the log when these methods are enabled.
      %i[remote requests].each do |recording_method|
        AppMap.recording_enabled?(recording_method)
      end

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

      http_hook_available = ActionController::Instrumentation.public_instance_methods.include?(:process_action)
      if http_hook_available
        AppMap::Handler::Rails::RequestHandler::HookMethod.new.activate
      else
        ActiveSupport::Notifications.subscribe(
          'start_processing.action_controller',
          AppMap::Handler::Rails::RequestHandler::RequestListener.method(:begin_request)
        )
      end

      AppMap::Handler::Rails::RequestHandler::RackHook.new.activate
    end
  end
end if AppMap.recording_enabled?

# frozen_string_literal: true

module AppMap
  # Railtie connects the AppMap recorder to Rails-specific features.
  class Railtie < ::Rails::Railtie
    initializer 'appmap.init' do |_| #  params: app
      AppMap.configure
    end

    # appmap.subscribe subscribes to ActiveSupport Notifications so that they can be recorded as
    # AppMap events.
    initializer 'appmap.subscribe', after: 'appmap.init' do |_| # params: app
      require 'appmap/rails/sql_handler'
      require 'appmap/rails/action_handler'
      ActiveSupport::Notifications.subscribe 'sql.sequel', AppMap::Rails::SQLHandler.new
      ActiveSupport::Notifications.subscribe 'sql.active_record', AppMap::Rails::SQLHandler.new
      ActiveSupport::Notifications.subscribe \
        'start_processing.action_controller', AppMap::Rails::ActionHandler::HTTPServerRequest.new
      ActiveSupport::Notifications.subscribe \
        'process_action.action_controller', AppMap::Rails::ActionHandler::HTTPServerResponse.new
    end
  end
end

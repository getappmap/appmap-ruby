# frozen_string_literal: true

module AppMap
  # Railtie connects the AppMap recorder to Rails-specific features.
  class Railtie < ::Rails::Railtie
    config.appmap = ActiveSupport::OrderedOptions.new

    initializer 'appmap.init' do |_| # params: app
      require 'appmap'
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

    # appmap.trace begins recording an AppMap trace and writes it to appmap.json.
    # This behavior is only activated if the configuration setting app.config.appmap.enabled
    # is truthy.
    initializer 'appmap.trace', after: 'appmap.subscribe' do |app|
      lambda do
        return unless app.config.appmap.enabled

        require 'appmap/command/record'
        require 'json'
        AppMap::Command::Record.new(AppMap.configuration).perform do |version, metadata, class_map, events|
          appmap = JSON.generate \
            version: version,
            metadata: metadata,
            classMap: class_map,
            events: events
          File.open('appmap.json', 'w').write(appmap)
        end
      end.call
    end
  end
end

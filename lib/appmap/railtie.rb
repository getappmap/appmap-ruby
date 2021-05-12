# frozen_string_literal: true

module AppMap
  # Railtie connects the AppMap recorder to Rails-specific features.
  class Railtie < ::Rails::Railtie
    config.appmap = ActiveSupport::OrderedOptions.new

    # appmap.subscribe subscribes to ActiveSupport Notifications so that they can be recorded as
    # AppMap events.
    initializer 'appmap.subscribe' do |_| # params: app
      require 'appmap/handler/rails/sql_handler'
      require 'appmap/handler/rails/request_handler'
      ActiveSupport::Notifications.subscribe 'sql.sequel', AppMap::Handler::Rails::SQLHandler.new
      ActiveSupport::Notifications.subscribe 'sql.active_record', AppMap::Handler::Rails::SQLHandler.new

      AppMap::Handler::Rails::RequestHandler::HookMethod.new.activate
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
end unless ENV['APPMAP_INITIALIZE'] == 'false'

module AppMap
  class Railtie < ::Rails::Railtie
    config.appmap = ActiveSupport::OrderedOptions.new

    initializer 'appmap.trace' do |app|
      lambda do
        return unless app.config.appmap.enabled

        require 'appmap'
        require 'appmap/config'
        config = AppMap::Config.load_from_file 'appmap.yml'

        require 'appmap/command/record'
        require 'json'
        AppMap::Command::Record.new(config).perform do |features, events|
          File.open('appmap.json', 'w').write JSON.generate(classMap: features, events: events)
        end
      end.call
    end

    initializer 'appmap.subscribe', after: 'appmap.trace' do |_| # params: app
      lambda do
        require 'appmap/rails/sql_handler'
        require 'appmap/rails/action_handler'
        ActiveSupport::Notifications.subscribe('sql.sequel', AppMap::Rails::SQLHandler.new)
        ActiveSupport::Notifications.subscribe('sql.active_record', AppMap::Rails::SQLHandler.new)
        ActiveSupport::Notifications.subscribe('start_processing.action_controller', AppMap::Rails::ActionHandler::HTTPServerRequest.new)
        ActiveSupport::Notifications.subscribe('process_action.action_controller', AppMap::Rails::ActionHandler::HTTPServerResponse.new)
      end.call
    end
  end
end

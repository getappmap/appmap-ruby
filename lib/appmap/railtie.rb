module AppMap
  class Railtie < ::Rails::Railtie
    config.appmap = ActiveSupport::OrderedOptions.new

    initializer 'appmap.trace' do |app|
      lambda do
        return unless app.config.appmap.enabled

        rspec_run = Thread.current.backtrace.find do |line|
          tokens = line.split(':')
          tokens.find { |t| t =~ %r{\/lib\/rspec\/core\/runner.rb$} } &&
            tokens.find { |t| t == "in `run'" }
        end
        return warn 'Not enabling the AppMap Railtie because we appear to be running in RSpec' \
          if rspec_run

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

    initializer 'appmap.subscribe', after: 'appmap.trace' do |app|
      lambda do
        return unless app.config.appmap.enabled

        require 'appmap/rails/sql_handler'
        ActiveSupport::Notifications.subscribe('sql.sequel', AppMap::Rails::SQLHandler.new)
      end.call
    end
  end
end

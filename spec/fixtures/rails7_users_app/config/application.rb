require_relative "boot"

def orm_module
  ENV['ORM_MODULE'] || 'sequel'
end

require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"
require "rails/test_unit/railtie"

case orm_module
when 'sequel'
  require 'sequel-rails'
  require 'sequel_secure_password'
  require 'database_cleaner-sequel' if Rails.env.test?
when 'activerecord'
  require 'active_record/railtie'
  require 'database_cleaner-active_record' if Rails.env.test?
end


# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(*Rails.groups)

module App
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 7.0

    # Configuration for the application, engines, and railties goes here.
    #
    # These settings can be overridden in specific environments using the files
    # in config/environments, which are processed later.
    #
    # config.time_zone = "Central Time (US & Canada)"
    # config.eager_load_paths << Rails.root.join("extras")
    config.api_only = true

    Rails.autoloaders.main.ignore << File.join(Rails.root, 'app/models')
    config.autoload_paths << File.join(Rails.root, "app/models/#{orm_module}")
  end
end

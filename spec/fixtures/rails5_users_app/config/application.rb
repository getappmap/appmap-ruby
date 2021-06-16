require_relative 'boot'

def orm_module
  ENV['ORM_MODULE'] || 'sequel'
end

require "rails"
# Pick the frameworks you want:
require "active_model/railtie"
require "active_job/railtie"
require "action_controller/railtie"
require "action_view/railtie"

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

module UsersApp
  class Application < Rails::Application
    # Initialize configuration defaults for originally generated Rails version.
    config.load_defaults 5.2

    # Settings in config/environments/* take precedence over those specified here.
    # Application configuration can go into files in config/initializers
    # -- all .rb files in that directory are automatically loaded after loading
    # the framework and any gems in your application.

    # Only loads a smaller set of middleware suitable for API only apps.
    # Middleware like session, flash, cookies can be added back manually.
    # Skip views, helpers and assets when generating a new resource.
    config.api_only = true

    config.autoload_paths << File.join(Rails.root, "app/models/#{orm_module}")
  end
end

# v0.7.0

* Provide `appmap/railtie` for integrating AppMap recording into Rails apps.
  * Use `gem :appmap, require: %w[appmap appmap/railtie]` to activate.
  * Set Rails configuration setting `config.appmap.enabled = true` to enable recording of the app via the Railtie, and
    to enable recording of RSpec tests via `appmap/rspec`.
  * In a non-Rails environment, set `APPMAP=true` to to enable recording of RSpec tests.
* SQL queries are reported as AppMap event `sql_query` data.
* Remove `self` attribute from `call` events.

# v0.6.0

* Web server requests and responses through WEBrick are reported as AppMap event `http_server_request` data.
* Rails `params` hash is reported as an AppMap event `message` data.
* Rails `request` is reported as an AppMap event `http_server_request` data.

# v0.5.1

* Add RSpec test recorder.

# v0.5.0

* Converted 'inspect', 'record' and 'upload' commands into a unified 'appmap' command with subcommands.
* Changed the standard name of the config file from .appmap.yml to appmap.yml.
* Updated appmap.yml configuration format.

# v0.4.0

Initial release.

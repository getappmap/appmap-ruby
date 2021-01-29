require 'rspec'
require 'net/http'
require 'json'
require 'yaml'
require 'English'
require 'byebug'
require 'webdrivers/chromedriver'

# Disable default initialization of AppMap
ENV['APPMAP_INITIALIZE'] = 'false'

require 'appmap'

RSpec.configure do |config|
  config.example_status_persistence_file_path = "tmp/rspec_failed_examples.txt"
end

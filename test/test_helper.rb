$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

# Disable default initialization of AppMap
ENV['APPMAP_INITIALIZE'] = 'false'
ENV.delete('RAILS_ENV')
ENV.delete('APP_ENV')

require 'appmap'

require 'minitest/autorun'
require 'diffy'
require 'active_support'
require 'active_support/core_ext'
require 'json'

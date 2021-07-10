$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'appmap'

require 'minitest/autorun'
require 'diffy'
require 'active_support'
require 'active_support/core_ext'
require 'json'
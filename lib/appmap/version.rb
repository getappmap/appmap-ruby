# frozen_string_literal: true

module AppMap
  URL = 'https://github.com/applandinc/appmap-ruby'

  VERSION = '0.62.0'

  APPMAP_FORMAT_VERSION = '1.5.1'

  SUPPORTED_RUBY_VERSIONS_REGEX = /^2\.[567]\./.freeze
  SUPPORTED_RUBY_VERSIONS = %w[2.5 2.6 2.7].freeze

  DEFAULT_APPMAP_DIR = 'tmp/appmap'.freeze
  DEFAULT_CONFIG_FILE_PATH = 'appmap.yml'.freeze
end

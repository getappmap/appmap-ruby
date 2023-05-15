# frozen_string_literal: true

module AppMap
  URL = 'https://github.com/applandinc/appmap-ruby'

  VERSION = '0.99.4'

  APPMAP_FORMAT_VERSION = '1.12.0'

  SUPPORTED_RUBY_VERSIONS = %w[2.5 2.6 2.7 3.0 3.1 3.2].freeze

  DEFAULT_APPMAP_DIR = 'tmp/appmap'.freeze
  DEFAULT_CONFIG_FILE_PATH = 'appmap.yml'.freeze
end

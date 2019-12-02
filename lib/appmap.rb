# frozen_string_literal: true

begin
  require 'active_support'
  require 'active_support/core_ext'
rescue NameError
  warn 'active_support is not available. AppMap execution will continue optimistically without it...'
end

require 'appmap/version'

module AppMap
  BATCH_HEADER_NAME = 'AppLand-Scenario-Batch'

  class << self
    # Simplified entry point to inspect code for features.
    def inspect(config)
      require 'appmap/inspect'
      features = config.source_locations.map(&AppMap::Inspect.method(:detect_features)).flatten.compact
      features = features.map(&:reparent)
      features.each(&:prune)
    end
  end
end

# require 'appmap/railtie' if defined?(Rails)

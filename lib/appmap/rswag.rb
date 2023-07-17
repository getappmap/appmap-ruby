# frozen_string_literal: true

require 'appmap'

module AppMap
  module Rswag
    def self.record(metadata, &block)
      description = metadata[:full_description]
      warn "Recording of RSwag test #{description}" if AppMap::RSpec::LOG
      source_location = (metadata[:example_group] || {})[:location]

      appmap = AppMap.record(&block)

      events = appmap['events']
      class_map = appmap['classMap']

      exception = (events.last || {})[:exception]
      failed = true if exception
      warn "Finishing recording of #{failed ? 'failed ' : ''} RSwag test #{description}" if AppMap::RSpec::LOG
      warn "Exception: #{exception}" if exception && AppMap::RSpec::LOG

      if failed
        warn "Failure exception: #{exception}" if AppMap::RSpec::LOG
        test_failure = Util.extract_test_failure(exception)
      end

      AppMap::RSpec.save name: description,
                         class_map: class_map,
                         source_location: source_location,
                         test_status: exception ? 'failed' : 'succeeded',
                         test_failure: test_failure,
                         exception: exception,
                         events: events,
                         frameworks: [
                           { name: 'rswag',
                             version: Gem.loaded_specs['rswag-specs']&.version&.to_s }
                         ],
                         recorder: {
                           name: 'rswag',
                           type: 'tests'
                         }
    end

    class << self
      def enabled?
        RSpec.enabled? && defined?(Rswag)
      end
    end
  end

  if Rswag.enabled?
    require 'rswag'
    require 'rswag/specs'
    require 'appmap/rspec'

    module ::Rswag
      module Specs
        module ExampleHelpers
          alias submit_request_without_appmap submit_request

          def submit_request(metadata)
            AppMap::Rswag.record(metadata) do
              submit_request_without_appmap(metadata)
            end
          end
        end
      end
    end
  end
end

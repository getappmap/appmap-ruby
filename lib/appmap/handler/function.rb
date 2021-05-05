# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Handler
    module Function
      class << self
        def handle_call(defined_class, hook_method, receiver, args)
          AppMap::Event::MethodCall.build_from_invocation(defined_class, hook_method, receiver, args)
        end

        def handle_return(call_event_id, elapsed, return_value, exception)
          AppMap::Event::MethodReturn.build_from_invocation(call_event_id, return_value, exception, elapsed: elapsed)
        end
      end
    end
  end
end

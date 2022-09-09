# frozen_string_literal: true

require 'appmap/event'
require 'appmap/hook/method'

module AppMap
  module Handler
    # Base handler class, will emit method call and return events.
    class FunctionHandler < Hook::Method
      def handle_call(receiver, args)
        AppMap::Event::MethodCall.build_from_invocation(defined_class, hook_method, receiver, args)
      end

      def handle_return(call_event_id, elapsed_before, elapsed, after_start_time, return_value, exception)
        AppMap::Event::MethodReturn.build_from_invocation(call_event_id, return_value, exception, elapsed_before: elapsed_before, elapsed: elapsed, after_start_time: after_start_time)
      end
    end
  end
end

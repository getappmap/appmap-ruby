# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Handler
    module Function
      def handle_call(defined_class, hook_method, receiver, args)
        AppMap::Event::MethodCall.build_from_invocation(defined_class, hook_method, receiver, args).tap do |call_event|
          AppMap.tracing.record_event call_event, package: hook_package, defined_class: defined_class, method: hook_method
        end
      end

      def handle_return(call_event_id, elapsed, return_value, exception)
        AppMap::Event::MethodReturn.build_from_invocation(call_event.id, elapsed, return_value, exception).tap do |return_event|
          AppMap.tracing.record_event return_event
        end
      end
    end
  end
end

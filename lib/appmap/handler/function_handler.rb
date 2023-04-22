# frozen_string_literal: true

require 'appmap/event'
require 'appmap/hook/method'

module AppMap
  module Handler
    # Base handler class, will emit method call and return events.
    class FunctionHandler < Hook::Method
      def handle_call(receiver, args)
        AppMap::Event::MethodCall.build_from_invocation(defined_class, hook_method, receiver, args).tap do |call|
          if hook_package.report_stack
            call.stack = caller[1..-1].select { |line| !line.include?('lib/appmap') }
          end
        end
      end

      def handle_return(call_event_id, elapsed, return_value, exception)
        AppMap::Event::MethodReturn.build_from_invocation(call_event_id, return_value, exception, elapsed: elapsed)
      end
    end
  end
end

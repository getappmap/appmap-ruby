# frozen_string_literal: true

def ruby2_keywords(*); end unless respond_to?(:ruby2_keywords, true)

module AppMap
  class Hook
    # Delegation methods for Ruby 2.
    # cf. https://eregon.me/blog/2019/11/10/the-delegation-challenge-of-ruby27.html
    class Method
      ruby2_keywords def call(receiver, *args, &block)
        call_event = trace? && with_disabled_hook { before_hook receiver, *args }
        # note we can't short-circuit directly to do_call because then the call stack
        # depth changes and eval handler doesn't work correctly
        trace_call call_event, receiver, *args, &block
      end

      protected

      def before_hook(receiver, *args)
        call_event = handle_call(receiver, args)
        if call_event
          AppMap.tracing.record_event \
            call_event,
            package: hook_package,
            defined_class: defined_class,
            method: hook_method
        end
        call_event
      end

      ruby2_keywords def do_call(receiver, *args, &block)
        hook_method.bind(receiver).call(*args, &block)
      end

      # rubocop:disable Metrics/MethodLength
      ruby2_keywords def trace_call(call_event, receiver, *args, &block)
        return do_call(receiver, *args, &block) unless call_event

        start_time = gettime
        begin
          return_value = do_call(receiver, *args, &block)
        rescue # rubocop:disable Style/RescueStandardError
          exception = $ERROR_INFO
          raise
        ensure
          with_disabled_hook { after_hook receiver, call_event, gettime - start_time, return_value, exception } \
            if call_event
        end
      end
      # rubocop:enable Metrics/MethodLength

      def hook_method_def
        this = self
        proc { |*args, &block| this.call self, *args, &block }.tap do |hook|
          hook.ruby2_keywords if hook.respond_to? :ruby2_keywords
        end
      end
    end
  end
end

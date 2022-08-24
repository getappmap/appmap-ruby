# frozen_string_literal: true

module AppMap
  class Hook
    # Delegation methods for Ruby 3.
    class Method
      def call(receiver, *args, **kwargs, &block)
        if trace?
          begin
            # Don't record functions, such as to_s and inspect, that
            # might be called by the fn. Otherwise there can be a
            # stack overflow.
            Thread.current[HOOK_DISABLE_KEY] = true
            call_event = before_hook(receiver, *args, **kwargs)
          ensure
            Thread.current[HOOK_DISABLE_KEY] = false
          end
        else
          call_event = false
        end

        # note we can't short-circuit directly to do_call because then the call stack
        # depth changes and eval handler doesn't work correctly
        trace_call call_event, receiver, *args, **kwargs, &block
      end

      protected

      def before_hook(receiver, *args, **kwargs)
        args = [*args, kwargs] if !kwargs.empty? || keyrest?
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

      def keyrest?
        @keyrest ||= parameters.map(&:last).include? :keyrest
      end

      def do_call(receiver, *args, **kwargs, &block)
        hook_method.bind_call(receiver, *args, **kwargs, &block)
      end

      # rubocop:disable Metrics/MethodLength
      def trace_call(call_event, receiver, *args, **kwargs, &block)
        return do_call(receiver, *args, **kwargs, &block) unless call_event

        start_time = gettime
        begin
          return_value = do_call(receiver, *args, **kwargs, &block)
        rescue # rubocop:disable Style/RescueStandardError
          exception = $ERROR_INFO
          raise
        ensure
          if call_event
            begin
              Thread.current[HOOK_DISABLE_KEY] = true
              after_hook(receiver, call_event, gettime - start_time, return_value, exception)
            ensure
              Thread.current[HOOK_DISABLE_KEY] = false
            end
          end
        end
      end
      # rubocop:enable Metrics/MethodLength

      def hook_method_def
        this = self
        proc { |*args, **kwargs, &block| this.call self, *args, **kwargs, &block }
      end
    end
  end
end

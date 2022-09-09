# frozen_string_literal: true

require 'appmap/util'

module AppMap
  class Hook
    # Delegation methods for Ruby 3.
    class Method
      def call(receiver, *args, **kwargs, &block)
        call_event = false
        if trace?
          call_event, elapsed_before = with_disabled_hook { before_hook receiver, *args, **kwargs }
        end
        # note we can't short-circuit directly to do_call because then the call stack
        # depth changes and eval handler doesn't work correctly
        trace_call call_event, elapsed_before, receiver, *args, **kwargs, &block
      end

      protected

      def before_hook(receiver, *args, **kwargs)
        before_hook_start_time = AppMap::Util.gettime()
        args = [*args, kwargs] if !kwargs.empty? || keyrest?
        call_event = handle_call(receiver, args)
        if call_event
          AppMap.tracing.record_event \
            call_event,
            package: hook_package,
            defined_class: defined_class,
            method: hook_method
        end
        [call_event, AppMap::Util.gettime() - before_hook_start_time]
      end

      def keyrest?
        @keyrest ||= parameters.map(&:last).include? :keyrest
      end

      def do_call(receiver, *args, **kwargs, &block)
        hook_method.bind_call(receiver, *args, **kwargs, &block)
      end

      # rubocop:disable Metrics/MethodLength
      def trace_call(call_event, elapsed_before, receiver, *args, **kwargs, &block)
        return do_call(receiver, *args, **kwargs, &block) unless call_event

        start_time = AppMap::Util.gettime()
        begin
          return_value = do_call(receiver, *args, **kwargs, &block)
        rescue # rubocop:disable Style/RescueStandardError
          exception = $ERROR_INFO
          raise
        ensure
          after_start_time = AppMap::Util.gettime()
          with_disabled_hook { after_hook receiver, call_event, elapsed_before, after_start_time - start_time, after_start_time, return_value, exception } \
            if call_event
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

# frozen_string_literal: true

module AppMap
  class Hook
    # Delegation methods for Ruby 3.
    class Method
      def call(receiver, *args, **kwargs, &block)
        return do_call(receiver, *args, **kwargs, &block) unless trace?

        call_event = with_disabled_hook { before_hook receiver, *args, **kwargs }
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

      def trace_call(call_event, receiver, *args, **kwargs, &block)
        start_time = gettime
        begin
          return_value = do_call(receiver, *args, **kwargs, &block)
        rescue # rubocop:disable Style/RescueStandardError
          exception = $ERROR_INFO
          raise
        ensure
          with_disabled_hook { after_hook receiver, call_event, gettime - start_time, return_value, exception } \
            if call_event
        end
      end

      def hook_method_def
        this = self
        proc { |*args, **kwargs, &block| this.call self, *args, **kwargs, &block }
      end
    end
  end
end
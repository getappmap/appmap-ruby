module AppMap
  class Hook
    class Method
      attr_reader :hook_class, :hook_method, :defined_class, :method_display_name

      HOOK_DISABLE_KEY = 'AppMap::Hook.disable'
      private_constant :HOOK_DISABLE_KEY

      # Grab the definition of Time.now here, to avoid interfering
      # with the method we're hooking.
      TIME_NOW = Time.method(:now)
      private_constant :TIME_NOW
      
      def initialize(hook_class, hook_method)
        @hook_class = hook_class
        @hook_method = hook_method
        @defined_class, method_symbol = Hook.qualify_method_name(@hook_method)
        @method_display_name = [@defined_class, method_symbol, @hook_method.name].join
      end

      def activate
        warn "AppMap: Hooking #{method_display_name}" if Hook::LOG

        hook_method = self.hook_method
        before_hook = self.method(:before_hook)
        after_hook = self.method(:after_hook)
        with_disabled_hook = self.method(:with_disabled_hook)

        hook_class.define_method hook_method.name do |*args, &block|
          instance_method = hook_method.bind(self).to_proc

          hook_disabled = Thread.current[HOOK_DISABLE_KEY]
          enabled = true if !hook_disabled && AppMap.tracing.enabled?
          return instance_method.call(*args, &block) unless enabled

          call_event, start_time = with_disabled_hook.() do
            before_hook.(self, args)
          end
          return_value = nil
          exception = nil
          begin
            return_value = instance_method.(*args, &block)
          rescue
            exception = $ERROR_INFO
            raise
          ensure
            with_disabled_hook.() do
              after_hook.(call_event, start_time, return_value, exception)
            end
          end
        end
      end

      protected

      def before_hook(receiver, args)
        require 'appmap/event'
        call_event = AppMap::Event::MethodCall.build_from_invocation(defined_class, hook_method, receiver, args)
        AppMap.tracing.record_event call_event, defined_class: defined_class, method: hook_method
        [ call_event, TIME_NOW.call ]
      end

      def after_hook(call_event, start_time, return_value, exception)
        require 'appmap/event'
        elapsed = TIME_NOW.call - start_time
        return_event = \
          AppMap::Event::MethodReturn.build_from_invocation call_event.id, elapsed, return_value, exception
        AppMap.tracing.record_event return_event
      end

      def with_disabled_hook(&fn)
        # Don't record functions, such as to_s and inspect, that might be called
        # by the fn. Otherwise there can be a stack overflow.
        Thread.current[HOOK_DISABLE_KEY] = true
        begin
          fn.call
        ensure
          Thread.current[HOOK_DISABLE_KEY] = false
        end
      end
    end
  end
end

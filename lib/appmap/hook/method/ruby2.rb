# frozen_string_literal: true

def ruby2_keywords(*); end unless respond_to?(:ruby2_keywords, true)

module AppMap
  class Hook
    # Delegation methods for Ruby 2.
    # cf. https://eregon.me/blog/2019/11/10/the-delegation-challenge-of-ruby27.html
    class Method
      ruby2_keywords def call(receiver, *args, &block)
        return do_call(receiver, *args, &block) unless trace?

        call_event = with_disabled_hook { before_hook receiver, *args }
        trace_call call_event, receiver, *args, &block
      end

      protected

      ruby2_keywords def do_call(receiver, *args, &block)
        hook_method.bind(receiver).call(*args, &block)
      end

      ruby2_keywords def trace_call(call_event, receiver, *args, &block)
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

      def hook_method_def
        this = self
        proc { |*args, &block| this.call self, *args, &block }.tap do |hook|
          hook.ruby2_keywords if hook.respond_to? :ruby2_keywords
        end
      end
    end
  end
end

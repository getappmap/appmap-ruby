# frozen_string_literal: true

module AppMap
  NEW_RUBY = Util.ruby_minor_version >= 2.7
  if NEW_RUBY && !Proc.instance_methods.include?(:ruby2_keywords)
    warn "Ruby is #{RUBY_VERSION}, but Procs don't respond to #ruby2_keywords"
  end

  class Hook
    SIGNATURES = {}

    LOOKUP_SIGNATURE = lambda do |id|
      method = super(id)
    
      signature = SIGNATURES[[ method.owner, method.name ]]
      if signature
        method.singleton_class.module_eval do
          define_method(:parameters) do
            signature
          end
        end
      end
    
      method
    end
    
    class Method
      attr_reader :hook_package, :hook_class, :hook_method

      # +method_display_name+ may be nil if name resolution gets
      # deferred until runtime (e.g. for a singleton method on an
      # embedded Struct).
      attr_reader :method_display_name

      HOOK_DISABLE_KEY = 'AppMap::Hook.disable'
      private_constant :HOOK_DISABLE_KEY

      # Grab the definition of Time.now here, to avoid interfering
      # with the method we're hooking.
      TIME_NOW = Time.method(:now)
      private_constant :TIME_NOW

      ARRAY_OF_EMPTY_HASH = [{}.freeze].freeze

      def initialize(hook_package, hook_class, hook_method)
        @hook_package = hook_package
        @hook_class = hook_class
        @hook_method = hook_method

        # Get the class for the method, if it's known.
        @defined_class, method_symbol = Hook.qualify_method_name(@hook_method)
        @method_display_name = [@defined_class, method_symbol, @hook_method.name].join if @defined_class
      end

      def activate
        if Hook::LOG
          msg = if method_display_name
                  "#{method_display_name}"
                else
                  "#{hook_method.name} (class resolution deferred)"
                end
          warn "AppMap: Hooking #{msg} at line #{(hook_method.source_location || []).join(':')}"
        end

        defined_class = @defined_class
        hook_package = self.hook_package
        hook_method = self.hook_method
        before_hook = self.method(:before_hook)
        after_hook = self.method(:after_hook)
        with_disabled_hook = self.method(:with_disabled_hook)

        is_array_containing_empty_hash = ->(obj) {
          obj.is_a?(Array) && obj.length == 1 && obj[0].is_a?(Hash) && obj[0].size == 0
        }

        call_instance_method = lambda do |receiver, args, &block|
          # https://github.com/applandinc/appmap-ruby/issues/153
          if NEW_RUBY && is_array_containing_empty_hash.(args) && hook_method.arity == 1
            hook_method.bind_call(receiver, {}, &block)
          else
            if NEW_RUBY
              hook_method.bind_call(receiver, *args, &block)
            else
              hook_method.bind(receiver).call(*args, &block)
            end
          end
        end

        hook_method_def = Proc.new do |*args, &block|
          # We may not have gotten the class for the method during
          # initialization (e.g. for a singleton method on an embedded
          # struct), so make sure we have it now.
          defined_class, = Hook.qualify_method_name(hook_method) unless defined_class

          reentrant = Thread.current[HOOK_DISABLE_KEY]
          disabled_by_shallow_flag = \
            -> { hook_package&.shallow? && AppMap.tracing.last_package_for_current_thread == hook_package }

          enabled = true if AppMap.tracing.enabled? && !reentrant && !disabled_by_shallow_flag.call

          enabled = false if %i[instance_eval instance_exec].member?(hook_method.name) && args.empty?

          return call_instance_method.call(self, args, &block) unless enabled

          call_event, start_time = with_disabled_hook.call do
            before_hook.call(self, defined_class, args)
          end
          return_value = nil
          exception = nil
          begin
            return_value = call_instance_method.call(self, args, &block)
          rescue
            exception = $ERROR_INFO
            raise
          ensure
            with_disabled_hook.call do
              after_hook.call(self, call_event, start_time, return_value, exception) if call_event
            end
          end
        end
        hook_method_def = hook_method_def.ruby2_keywords if hook_method_def.respond_to?(:ruby2_keywords)

        hook_method_parameters = hook_method.parameters.dup.freeze
        SIGNATURES[[ hook_class, hook_method.name ]] = hook_method_parameters

        # irb(main):001:0> Kernel.public_instance_method(:system)
        # (irb):1:in `public_instance_method': method `system' for module `Kernel' is  private (NameError)
        if hook_class == Kernel
          hook_class.define_method_with_arity(hook_method.name, hook_method.arity, hook_method_def)
        else
          hook_class.ancestors.find { |cls| cls.method_defined?(hook_method.name, false) }.tap do |cls|
            if cls
              cls.define_method_with_arity(hook_method.name, hook_method.arity, hook_method_def)
            else
              warn "#{hook_method.name} not found on #{hook_class}"
            end
          end
        end
      end

      protected

      def before_hook(receiver, defined_class, args)
        call_event = hook_package.handler_class.handle_call(defined_class, hook_method, receiver, args)
        AppMap.tracing.record_event(call_event, package: hook_package, defined_class: defined_class, method: hook_method) if call_event
        [ call_event, TIME_NOW.call ]
      end

      def after_hook(_receiver, call_event, start_time, return_value, exception)
        elapsed = TIME_NOW.call - start_time
        return_event = hook_package.handler_class.handle_return(call_event.id, elapsed, return_value, exception)
        AppMap.tracing.record_event(return_event) if return_event
        nil
      end

      def with_disabled_hook(&function)
        # Don't record functions, such as to_s and inspect, that might be called
        # by the fn. Otherwise there can be a stack overflow.
        Thread.current[HOOK_DISABLE_KEY] = true
        begin
          function.call
        ensure
          Thread.current[HOOK_DISABLE_KEY] = false
        end
      end
    end
  end

  module ObjectMethods
    define_method(:method, AppMap::Hook::LOOKUP_SIGNATURE)
    define_method(:public_method, AppMap::Hook::LOOKUP_SIGNATURE)
    define_method(:singleton_method, AppMap::Hook::LOOKUP_SIGNATURE)
  end

  module ModuleMethods
    define_method(:instance_method, AppMap::Hook::LOOKUP_SIGNATURE)
    define_method(:public_instance_method, AppMap::Hook::LOOKUP_SIGNATURE)
  end
end

unless ENV['APPMAP_NO_PATCH_OBJECT'] == 'true'
  class Object
    prepend AppMap::ObjectMethods
  end
end

unless ENV['APPMAP_NO_PATCH_MODULE'] == 'true'
  class Module
    prepend AppMap::ModuleMethods
  end
end

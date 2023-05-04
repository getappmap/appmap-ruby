# frozen_string_literal: true

require 'appmap/util'

module AppMap
  class Hook
    class << self
      def method_hash_key(cls, method)
        [ cls, method.name ].hash
      rescue TypeError => e
        warn "Error building hash key for #{cls}, #{method}: #{e}"
      end
    end
    

    SIGNATURES = {}
    LOOKUP_SIGNATURE = lambda do |id|
      method = super(id)

      hash_key = Hook.method_hash_key(method.owner, method)
      return method unless hash_key

      signature = SIGNATURES[hash_key]
      if signature
        method.singleton_class.module_eval do
          define_method(:parameters) do
            signature
          end
        end
      end

      method
    end

    RUBY_MAJOR_VERSION, RUBY_MINOR_VERSION, _ = RUBY_VERSION.split('.').map(&:to_i)

    # Single hooked method.
    # Call #activate to override the original.
    class Method
      attr_reader :hook_package, :hook_class, :hook_method, :parameters, :arity

      HOOK_DISABLE_KEY = 'AppMap::Hook.disable'

      def initialize(hook_package, hook_class, hook_method)
        @hook_package = hook_package
        @hook_class = hook_class
        @hook_method = hook_method
        @parameters = hook_method.parameters
        @arity = hook_method.arity
      end

      def activate
        if HookLog.enabled?
          msg = if method_display_name
              "#{method_display_name}"
            else
              "#{hook_method.name} (class resolution deferred)"
            end
          HookLog.log "Hooking #{msg} at line #{(hook_method.source_location || []).join(':')}"
        end

        hook_method_parameters = hook_method.parameters.dup.freeze
        hash_key = Hook.method_hash_key(hook_class, hook_method)
        SIGNATURES[hash_key] = hook_method_parameters if hash_key

        # irb(main):001:0> Kernel.public_instance_method(:system)
        # (irb):1:in `public_instance_method': method `system' for module `Kernel' is  private (NameError)
        if hook_class == Kernel
          hook_class.define_method_with_arity(hook_method.name, hook_method.arity, hook_method_def)
        else
          cls = defining_class(hook_class)
          if cls
            cls.define_method_with_arity(hook_method.name, hook_method.arity, hook_method_def)
          end
        end
      end

      protected

      def defining_class(hook_class)
        cls = if RUBY_MAJOR_VERSION == 2 && RUBY_MINOR_VERSION <= 5
            hook_class
              .ancestors
              .select { |cls| cls.method_defined?(hook_method.name) }
              .find { |cls| cls.instance_method(hook_method.name).owner == cls }
          else
            hook_class.ancestors.find { |cls| cls.method_defined?(hook_method.name, false) }
          end

        return cls if cls

        warn "#{hook_method.name} not found on #{hook_class}" if Hook::LOG
      end

      def trace?
        return false unless AppMap.tracing_enabled?
        return false if Thread.current[HOOK_DISABLE_KEY]
        return false if hook_package&.shallow? && AppMap.tracing.last_package_for_current_thread == hook_package

        true
      end

      def method_display_name
        return @method_display_name if @method_display_name

        return @method_display_name = [defined_class, '#', hook_method.name].join if defined_class

        "#{hook_method.name} (class resolution deferred)"
      end

      def defined_class
        @defined_class ||= Hook.qualify_method_name(hook_method)&.first
      end

      def after_hook(_receiver, call_event, elapsed_before, elapsed, after_start_time, return_value, exception)
        return_event = handle_return(call_event.id, elapsed, return_value, exception)
        return_event.elapsed_instrumentation = elapsed_before + (AppMap::Util.gettime() - after_start_time)
        AppMap.tracing.record_event(return_event) if return_event
      end

      def with_disabled_hook
        # Don't record functions, such as to_s and inspect, that might be called
        # by the fn. Otherwise there can be a stack overflow.
        Thread.current[HOOK_DISABLE_KEY] = true
        yield
      ensure
        Thread.current[HOOK_DISABLE_KEY] = false
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

if RUBY_VERSION < '3'
  require 'appmap/hook/method/ruby2'
else
  require 'appmap/hook/method/ruby3'
end

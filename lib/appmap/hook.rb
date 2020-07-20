# frozen_string_literal: true

require 'English'

module AppMap
  class Hook
    LOG = false

    HOOK_DISABLE_KEY = 'AppMap::Hook.disable'

    class << self
      # Return the class, separator ('.' or '#'), and method name for
      # the given method.
      def qualify_method_name(method)
        if method.owner.singleton_class?
          # Singleton class names can take two forms:
          # #<Class:Foo> or
          # #<Class:#<Bar:0x0123ABC>>. Retrieve the name of
          # the class from the string.
          # 
          # (There really isn't a better way to do this. The
          # singleton's reference to the class it was created
          # from is stored in an instance variable named
          # '__attached__'. It doesn't have the '@' prefix, so
          # it's internal only, and not accessible from user
          # code.)
          class_name = /#<Class:((#<(?<cls>.*?):)|((?<cls>.*?)>))/.match(method.owner.to_s)['cls']
          [ class_name, '.', method.name ]
        else
          [ method.owner.name, '#', method.name ]
        end
      end
    end
    
    attr_reader :config
    def initialize(config)
      @config = config
    end
    

    # Observe class loading and hook all methods which match the config.
    def enable &block
      before_hook = lambda do |defined_class, method, receiver, args|
        require 'appmap/event'
        call_event = AppMap::Event::MethodCall.build_from_invocation(defined_class, method, receiver, args)
        AppMap.tracing.record_event call_event, defined_class: defined_class, method: method
        [ call_event, Time.now ]
      end

      after_hook = lambda do |call_event, defined_class, method, start_time, return_value, exception|
        require 'appmap/event'
        elapsed = Time.now - start_time
        return_event = AppMap::Event::MethodReturn.build_from_invocation \
                                                     defined_class, method, call_event.id, elapsed, return_value, exception
        AppMap.tracing.record_event return_event
      end

      with_disabled_hook = lambda do |&fn|
        # Don't record functions, such as to_s and inspect, that might be called
        # by the fn. Otherwise there can be a stack overflow.
        Thread.current[HOOK_DISABLE_KEY] = true
        begin
          fn.call
        ensure
          Thread.current[HOOK_DISABLE_KEY] = false
        end
      end

      tp = TracePoint.new(:end) do |tp|
        hook = self
        cls = tp.self
        
        instance_methods = cls.public_instance_methods(false)
        class_methods = cls.singleton_class.public_instance_methods(false) - instance_methods

        hook_method = lambda do |cls|
          lambda do |method_id|
            next if method_id.to_s =~ /_hooked_by_appmap$/

            method = cls.public_instance_method(method_id)
            disasm = RubyVM::InstructionSequence.disasm(method)
            # Skip methods that have no instruction sequence, as they are obviously trivial.
            next unless disasm
            
            defined_class, method_symbol, method_name = Hook.qualify_method_name(method)
            method_display_name = [defined_class,method_symbol,method_name].join

            # Don't try and trace the AppMap methods or there will be
            # a stack overflow in the defined hook method.
            next if /\AAppMap[:\.]/.match?(method_display_name) 

            next unless \
              config.always_hook?(defined_class, method_name) ||
              config.included_by_location?(method)

            warn "AppMap: Hooking #{method_display_name}" if LOG

            cls.define_method method_id do |*args, &block|
              base_method = method.bind(self).to_proc

              hook_disabled = Thread.current[HOOK_DISABLE_KEY]
              enabled = true if !hook_disabled && AppMap.tracing.enabled?
              return base_method.call(*args, &block) unless enabled

              call_event, start_time = with_disabled_hook.call do
                before_hook.call(defined_class, method, self, args)
              end
              return_value = nil
              exception = nil
              begin
                return_value = base_method.call(*args, &block)
              rescue
                exception = $ERROR_INFO
                raise
              ensure
                with_disabled_hook.call do
                  after_hook.call(call_event, defined_class, method, start_time, return_value, exception)
                end
              end
            end
          end
        end

        instance_methods.each(&hook_method.call(cls))
        class_methods.each(&hook_method.call(cls.singleton_class))
      end

      tp.enable &block
    end
  end
end

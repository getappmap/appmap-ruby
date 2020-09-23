# frozen_string_literal: true

require 'English'

module AppMap
  class Hook
    LOG = (ENV['DEBUG'] == 'true')

    @unbound_method_arity = ::UnboundMethod.instance_method(:arity)
    @method_arity = ::Method.instance_method(:arity)

    class << self
      def lock_builtins
        return if @builtins_hooked

        @builtins_hooked = true
      end

      # Return the class, separator ('.' or '#'), and method name for
      # the given method.
      def qualify_method_name(method)
        if method.owner.singleton_class?
          class_name = singleton_method_owner_name(method)
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
      require 'appmap/hook/method'

      hook_builtins

      tp = TracePoint.new(:end) do |trace_point|
        cls = trace_point.self

        instance_methods = cls.public_instance_methods(false)
        class_methods = cls.singleton_class.public_instance_methods(false) - instance_methods

        hook = lambda do |hook_cls|
          lambda do |method_id|
            method = hook_cls.public_instance_method(method_id)
            hook_method = Hook::Method.new(hook_cls, method)

            warn "AppMap: Examining #{hook_cls} #{method.name}" if LOG

            disasm = RubyVM::InstructionSequence.disasm(method)
            # Skip methods that have no instruction sequence, as they are obviously trivial.
            next unless disasm

            # Don't try and trace the AppMap methods or there will be
            # a stack overflow in the defined hook method.
            next if /\AAppMap[:\.]/.match?(hook_method.method_display_name)

            next unless \
              config.always_hook?(hook_cls, method.name) ||
              config.included_by_location?(method)

            hook_method.activate
          end
        end

        instance_methods.each(&hook.(cls))
        class_methods.each(&hook.(cls.singleton_class))
      end

      tp.enable(&block)
    end

    def hook_builtins
      return unless self.class.lock_builtins

      class_from_string = lambda do |fq_class|
        fq_class.split('::').inject(Object) do |mod, class_name|
          mod.const_get(class_name)
        end
      end

      Config::BUILTIN_METHODS.each do |class_name, hook|
        require hook.package.package_name if hook.package.package_name
        Array(hook.method_names).each do |method_name|
          method_name = method_name.to_sym
          cls = class_from_string.(class_name)
          method = \
            begin
              cls.instance_method(method_name)
            rescue NameError
              cls.method(method_name) rescue nil
            end

          if method
            Hook::Method.new(cls, method).activate
          else
            warn "Method #{method_name} not found on #{cls.name}" 
          end
        end
      end
    end
  end
end

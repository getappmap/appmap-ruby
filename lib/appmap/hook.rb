# frozen_string_literal: true

require 'English'

module AppMap
  class Hook
    LOG = (ENV['APPMAP_DEBUG'] == 'true' || ENV['DEBUG'] == 'true')

    OBJECT_INSTANCE_METHODS = %i[! != !~ <=> == === =~ __id__ __send__ class clone define_singleton_method display dup enum_for eql? equal? extend freeze frozen? hash inspect instance_eval instance_exec instance_of? instance_variable_defined? instance_variable_get instance_variable_set instance_variables is_a? itself kind_of? method methods nil? object_id private_methods protected_methods public_method public_methods public_send remove_instance_variable respond_to? send singleton_class singleton_method singleton_methods taint tainted? tap then to_enum to_s to_h to_a trust untaint untrust untrusted? yield_self].freeze
    OBJECT_STATIC_METHODS = %i[! != !~ < <= <=> == === =~ > >= __id__ __send__ alias_method allocate ancestors attr attr_accessor attr_reader attr_writer autoload autoload? class class_eval class_exec class_variable_defined? class_variable_get class_variable_set class_variables clone const_defined? const_get const_missing const_set constants define_method define_singleton_method deprecate_constant display dup enum_for eql? equal? extend freeze frozen? hash include include? included_modules inspect instance_eval instance_exec instance_method instance_methods instance_of? instance_variable_defined? instance_variable_get instance_variable_set instance_variables is_a? itself kind_of? method method_defined? methods module_eval module_exec name new nil? object_id prepend private_class_method private_constant private_instance_methods private_method_defined? private_methods protected_instance_methods protected_method_defined? protected_methods public_class_method public_constant public_instance_method public_instance_methods public_method public_method_defined? public_methods public_send remove_class_variable remove_instance_variable remove_method respond_to? send singleton_class singleton_class? singleton_method singleton_methods superclass taint tainted? tap then to_enum to_s trust undef_method untaint untrust untrusted? yield_self].freeze

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

        instance_methods = cls.public_instance_methods(false) - OBJECT_INSTANCE_METHODS
        # NoMethodError: private method `singleton_class' called for Rack::MiniProfiler:Class
        class_methods = begin
          if cls.respond_to?(:singleton_class)
            cls.singleton_class.public_instance_methods(false) - instance_methods - OBJECT_STATIC_METHODS
          else
            []
          end
        rescue NameError
          []
        end

        hook = lambda do |hook_cls|
          lambda do |method_id|
            # Don't try and trace the AppMap methods or there will be
            # a stack overflow in the defined hook method.
            return if (hook_cls&.name || '').split('::')[0] == AppMap.name

            method = begin
              hook_cls.public_instance_method(method_id)
            rescue NameError
              warn "AppMap: Method #{hook_cls} #{method.name} is not accessible" if LOG
              return
            end

            warn "AppMap: Examining #{hook_cls} #{method.name}" if LOG

            disasm = RubyVM::InstructionSequence.disasm(method)
            # Skip methods that have no instruction sequence, as they are obviously trivial.
            next unless disasm

            next if config.never_hook?(method)

            next unless \
              config.always_hook?(hook_cls, method.name) ||
              config.included_by_location?(method)

            package = config.package_for_method(method)

            hook_method = Hook::Method.new(package, hook_cls, method)

            hook_method.activate
          end
        end

        instance_methods.each(&hook.(cls))
        # NoMethodError: private method `singleton_class' called for Rack::MiniProfiler:Class
        begin
          class_methods.each(&hook.(cls.singleton_class)) if cls.respond_to?(:singleton_class)
        rescue NameError
          # NameError:
          #   uninitialized constant Faraday::Connection
        end
      end

      tp.enable(&block)
    end

    # hook_builtins builds hooks for code that is built in to the Ruby standard library.
    # No TracePoint events are emitted for builtins, so a separate hooking mechanism is needed. 
    def hook_builtins
      return unless self.class.lock_builtins

      class_from_string = lambda do |fq_class|
        fq_class.split('::').inject(Object) do |mod, class_name|
          mod.const_get(class_name)
        end
      end

      config.builtin_methods.each do |class_name, hooks|
        Array(hooks).each do |hook|
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

            next if config.never_hook?(method)

            if method
              Hook::Method.new(hook.package, cls, method).activate
            else
              warn "Method #{method_name} not found on #{cls.name}"
            end
          end
        end
      end
    end
  end
end

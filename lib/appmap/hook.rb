# frozen_string_literal: true

require 'English'

module AppMap
  class Hook
    LOG = (ENV['APPMAP_DEBUG'] == 'true' || ENV['DEBUG'] == 'true')
    LOG_HOOK = (ENV['DEBUG_HOOK'] == 'true')

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
      @trace_locations = []
      # Paths that are known to be non-tracing
      @notrace_paths = Set.new
    end

    # Observe class loading and hook all methods which match the config.
    def enable(&block)
      require 'appmap/hook/method'

      hook_builtins

      @trace_begin = TracePoint.new(:class, &method(:trace_class))
      @trace_end = TracePoint.new(:end, &method(:trace_end))

      @trace_begin.enable(&block)
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

      config.builtin_hooks.each do |class_name, hooks|
        Array(hooks).each do |hook|
          require hook.package.package_name if hook.package.package_name
          Array(hook.method_names).each do |method_name|
            method_name = method_name.to_sym
            base_cls = class_from_string.(class_name)

            hook_method = lambda do |entry|
              cls, method = entry
              return false if config.never_hook?(cls, method)

              Hook::Method.new(hook.package, cls, method).activate
            end

            methods = []
            methods << [ base_cls, base_cls.public_instance_method(method_name) ] rescue nil
            if base_cls.respond_to?(:singleton_class)
              methods << [ base_cls.singleton_class, base_cls.singleton_class.public_instance_method(method_name) ] rescue nil
            end
            methods.compact!
            if methods.empty?
              warn "Method #{method_name} not found on #{base_cls.name}"
            else
              methods.each(&hook_method)
            end
          end
        end
      end
    end

    protected

    def trace_class(trace_point)
      path = trace_point.path

      return if @notrace_paths.member?(path)

      if config.path_enabled?(path)
        location = trace_location(trace_point)
        warn "Entering hook-enabled location #{location}" if Hook::LOG || Hook::LOG_HOOK
        @trace_locations << location
        unless @trace_end.enabled?
          warn "Enabling hooking" if Hook::LOG || Hook::LOG_HOOK
          @trace_end.enable
        end
      else
        @notrace_paths << path
      end
    end

    def trace_location(trace_point)
      [ trace_point.path, trace_point.lineno ].join(':')
    end

    def trace_end(trace_point)
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
          next if %w[Marshal AppMap ActiveSupport].member?((hook_cls&.name || '').split('::')[0])

          next if method_id == :call

          method = begin
            hook_cls.public_instance_method(method_id)
          rescue NameError
            warn "AppMap: Method #{hook_cls} #{method.name} is not accessible" if LOG
            next
          end

          warn "AppMap: Examining #{hook_cls} #{method.name}" if LOG

          disasm = RubyVM::InstructionSequence.disasm(method)
          # Skip methods that have no instruction sequence, as they are obviously trivial.
          next unless disasm

          package = config.lookup_package(hook_cls, method)
          next unless package

          Hook::Method.new(package, hook_cls, method).activate
        end
      end

      instance_methods.each(&hook.(cls))
      begin
        # NoMethodError: private method `singleton_class' called for Rack::MiniProfiler:Class
        class_methods.each(&hook.(cls.singleton_class)) if cls.respond_to?(:singleton_class)
      rescue NameError
        # NameError:
        #   uninitialized constant Faraday::Connection
        warn "NameError in #{__FILE__}: #{$!.message}"
      end

      location = @trace_locations.pop
      warn "Leaving hook-enabled location #{location}" if Hook::LOG || Hook::LOG_HOOK
      if @trace_locations.empty?
        warn "Disabling hooking" if Hook::LOG || Hook::LOG_HOOK
        @trace_end.disable
      end
    end
  end
end

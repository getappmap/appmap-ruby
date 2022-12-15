# frozen_string_literal: true

require 'English'
require_relative './hook_log'

module AppMap
  class Hook
    OBJECT_INSTANCE_METHODS = %i[! != !~ <=> == === =~ __id__ __send__ class clone define_singleton_method display dup
                                 enum_for eql? equal? extend freeze frozen? hash inspect instance_eval instance_exec instance_of? instance_variable_defined? instance_variable_get instance_variable_set instance_variables is_a? itself kind_of? method methods nil? object_id private_methods protected_methods public_method public_methods public_send remove_instance_variable respond_to? send singleton_class singleton_method singleton_methods taint tainted? tap then to_enum to_s to_h to_a trust untaint untrust untrusted? yield_self].freeze
    OBJECT_STATIC_METHODS = %i[! != !~ < <= <=> == === =~ > >= __id__ __send__ alias_method allocate ancestors attr
                               attr_accessor attr_reader attr_writer autoload autoload? class class_eval class_exec class_variable_defined? class_variable_get class_variable_set class_variables clone const_defined? const_get const_missing const_set constants define_method define_singleton_method deprecate_constant display dup enum_for eql? equal? extend freeze frozen? hash include include? included_modules inspect instance_eval instance_exec instance_method instance_methods instance_of? instance_variable_defined? instance_variable_get instance_variable_set instance_variables is_a? itself kind_of? method method_defined? methods module_eval module_exec name new nil? object_id prepend private_class_method private_constant private_instance_methods private_method_defined? private_methods protected_instance_methods protected_method_defined? protected_methods public_class_method public_constant public_instance_method public_instance_methods public_method public_method_defined? public_methods public_send remove_class_variable remove_instance_variable remove_method respond_to? send singleton_class singleton_class? singleton_method singleton_methods superclass taint tainted? tap then to_enum to_s trust undef_method untaint untrust untrusted? yield_self].freeze
    SLOW_PACKAGE_THRESHOLD = 0.001

    @unbound_method_arity = ::UnboundMethod.instance_method(:arity)
    @method_arity = ::Method.instance_method(:arity)

    class << self
      def hook_builtins?
        Mutex.new.synchronize do
          @hook_builtins = true if @hook_builtins.nil?

          next false unless @hook_builtins

          @hook_builtins = false
          true
        end
      end

      def already_hooked?(method)
        # After a method is defined, the statement "module_function <the-method>" can convert that method
        # into a module (class) method. The method is hooked first when it's defined, then AppMap will attempt to
        # hook it again when it's redefined as a module method. So we check the method source location - if it's
        # part of the AppMap source tree, we ignore it.
        method.source_location && method.source_location[0].index(__dir__) == 0
      end

      # Return the class, separator ('.' or '#'), and method name for
      # the given method.
      def qualify_method_name(method)
        if method.owner.singleton_class?
          class_name = singleton_method_owner_name(method)
          [class_name, '.', method.name]
        else
          [method.owner.name, '#', method.name]
        end
      end
    end

    attr_reader :config

    def initialize(config)
      @config = config
      @trace_enabled = []
    end

    # Observe class loading and hook all methods which match the config.
    def enable(&block)
      require 'appmap/hook/method'

      hook_builtins

      # Paths that are known to be non-tracing.
      @notrace_paths = Set.new
      # Locations that have already been visited.
      @trace_locations = Set.new
      @module_load_times = Hash.new { |memo, k| memo[k] = 0 }
      @slow_packages = Set.new

      if ENV['APPMAP_PROFILE_HOOK'] == 'true'
        dump_times = lambda do
          @module_load_times
            .keys
            .select { |key| !@slow_packages.member?(key) }
            .each do |key|
            elapsed = @module_load_times[key]
            if elapsed >= SLOW_PACKAGE_THRESHOLD
              @slow_packages.add(key)
              warn "AppMap: Package #{key} took #{@module_load_times[key]} seconds to hook"
            end
          end
        end

        at_exit &dump_times
        Thread.new do
          while true
            dump_times.call
            sleep 5
          end
        end
      end

      @trace_end = TracePoint.new(:end, &method(:trace_end))
      @trace_end.enable(&block)
    end

    # hook_builtins builds hooks for code that is built in to the Ruby standard library.
    # No TracePoint events are emitted for builtins, so a separate hooking mechanism is needed.
    def hook_builtins
      return unless self.class.hook_builtins?

      hook_loaded_code = lambda do |hooks_by_class, builtin|
        hooks_by_class.each do |class_name, hooks|
          Array(hooks).each do |hook|
            HookLog.builtin class_name do
              if builtin && hook.package.require_name && hook.package.require_name != 'ruby'
                begin
                  require hook.package.require_name
                rescue
                  HookLog.load_error hook.package.require_name, "Unable to require #{hook.package.require_name}: #{$!}" if HookLog.enabled?
                  next
                end
              end
  
              begin
                base_cls = Object.const_get class_name
              rescue NameError
                HookLog.load_error class_name, "Class #{class_name} not found in global scope" if HookLog.enabled?
                next
              end
  
              Array(hook.method_names).each do |method_name|
                method_name = method_name.to_sym
  
                hook_method = lambda do |entry|
                  cls, method = entry
                  next if config.never_hook?(cls, method)
  
                  hook.package.handler_class.new(hook.package, cls, method).activate
                end
  
                methods = []
                # irb(main):001:0> Kernel.public_instance_method(:system)
                # (irb):1:in `public_instance_method': method `system' for module `Kernel' is  private (NameError)
                if base_cls == Kernel
                  methods << [base_cls, base_cls.instance_method(method_name)] rescue nil
                end
                methods << [base_cls, base_cls.public_instance_method(method_name)] rescue nil
                methods << [base_cls, base_cls.protected_instance_method(method_name)] rescue nil
                if base_cls.respond_to?(:singleton_class)
                  methods << [base_cls.singleton_class, base_cls.singleton_class.public_instance_method(method_name)] rescue nil
                  methods << [base_cls.singleton_class, base_cls.singleton_class.protected_instance_method(method_name)] rescue nil
                end
                methods.compact!
                if methods.empty?
                  HookLog.load_error [ base_cls.name, method_name ].join('[#.]'), "Method #{method_name} not found on #{base_cls.name}" if HookLog.enabled?
                else
                  methods.each(&hook_method)
                end
              end
            end
          end
        end
      end

      hook_loaded_code.(config.builtin_hooks, true)
    end

    protected

    def trace_location(trace_point)
      [trace_point.path, trace_point.lineno].join(':')
    end

    def trace_end(trace_point)
      location = trace_location(trace_point)
      return unless @trace_locations.add?(location)
      HookLog.on_load location do
        path = trace_point.path
        enabled = !@notrace_paths.member?(path) && config.path_enabled?(path)
        unless enabled
          HookLog.log 'Not hooking - path is not enabled' if HookLog.enabled?
          @notrace_paths << path
          next
        end

        cls = trace_point.self

        instance_methods = cls.public_instance_methods(false) + cls.protected_instance_methods(false) - OBJECT_INSTANCE_METHODS
        # NoMethodError: private method `singleton_class' called for Rack::MiniProfiler:Class
        class_methods = begin
            if cls.respond_to?(:singleton_class)
              cls.singleton_class.public_instance_methods(false) + cls.singleton_class.protected_instance_methods(false) - instance_methods - OBJECT_STATIC_METHODS
            else
              []
            end
          rescue NameError
            []
          end

        hook = lambda do |hook_cls|
          lambda do |method_id|
            method = begin
                hook_cls.instance_method(method_id)
              rescue NameError
                HookLog.load_error [ hook_cls, method_id ].join('[#.]'), "Method #{hook_cls} #{method_id} is not accessible: #{$!}" if HookLog.enabled?
                next
              end

            package = config.lookup_package(hook_cls, method)
            # doing this check first returned early in 98.7% of cases in sample_app_6th_ed
            next unless package

            # Don't try and trace the AppMap methods or there will be
            # a stack overflow in the defined hook method.
            next if %w[Marshal AppMap ActiveSupport].member?((hook_cls&.name || '').split('::')[0])

            next if method_id == :call

            next if self.class.already_hooked?(method)

            HookLog.log "Examining #{hook_cls} #{method.name}" if HookLog.enabled?

            disasm = RubyVM::InstructionSequence.disasm(method)
            # Skip methods that have no instruction sequence, as they are either have no body or they are or native.
            # TODO: Figure out how to tell the difference?
            next unless disasm

            package.handler_class.new(package, hook_cls, method).activate
          end
        end

        start = Time.now
        instance_methods.each(&hook.(cls))
        begin
          # NoMethodError: private method `singleton_class' called for Rack::MiniProfiler:Class
          class_methods.each(&hook.(cls.singleton_class)) if cls.respond_to?(:singleton_class)
        rescue NameError
          # NameError:
          #   uninitialized constant Faraday::Connection
          warn "NameError in #{__FILE__}: #{$!.message}"
        end
        elapsed = Time.now - start
        if location.index(Bundler.bundle_path.to_s) == 0
          package_tokens = location[Bundler.bundle_path.to_s.length + 1..-1].split('/')
          @module_load_times[package_tokens[1]] += elapsed
        else
          file_path = location[Dir.pwd.length + 1..-1]
          if file_path
            location = file_path.split('/', 3)[0..1].join('/')
            @module_load_times[location] += elapsed
          end
        end
      end
    end
  end
end

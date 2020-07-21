# frozen_string_literal: true

require 'English'

module AppMap
  class Hook
    LOG = (ENV['DEBUG'] == 'true')

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
      require 'appmap/hook/method'

      tp = TracePoint.new(:end) do |trace_point|
        cls = trace_point.self

        instance_methods = cls.public_instance_methods(false)
        class_methods = cls.singleton_class.public_instance_methods(false) - instance_methods

        hook = lambda do |hook_cls|
          lambda do |method_id|
            next if method_id.to_s =~ /_hooked_by_appmap$/

            method = hook_cls.public_instance_method(method_id)
            hook_method = Hook::Method.new(hook_cls, method)

            warn "AppMap: Examining #{hook_method.method_display_name}" if LOG

            disasm = RubyVM::InstructionSequence.disasm(method)
            # Skip methods that have no instruction sequence, as they are obviously trivial.
            next unless disasm

            # Don't try and trace the AppMap methods or there will be
            # a stack overflow in the defined hook method.
            next if /\AAppMap[:\.]/.match?(hook_method.method_display_name)

            next unless \
              config.always_hook?(hook_method.defined_class, method.name) ||
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
      class_from_string = lambda do |fq_class|
        fq_class.split('::').inject(Object) do |mod, class_name|
          mod.const_get(class_name)
        end
      end

      Config::BUILTIN_METHODS.each do |class_name, methods|
        methods.each do |method_name, package|
          require package.package_name if package.package_name
          cls = class_from_string.(class_name)
          method = cls.instance_method(method_name.to_sym) || cls.class_method(method_name.to_sym)
          raise "Method #{method.inspect} not found on #{cls.name}" unless method

          Hook::Method.new(cls, method).activate
        end
      end
    end
  end
end

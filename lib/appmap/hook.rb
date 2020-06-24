# frozen_string_literal: true

require 'English'

module AppMap
  class Hook
    LOG = false

    Package = Struct.new(:path, :exclude) do
      def to_h
        {
          path: path,
          exclude: exclude.blank? ? nil : exclude
        }.compact
      end
    end

    Config = Struct.new(:name, :packages) do
      class << self
        # Loads configuration data from a file, specified by the file name.
        def load_from_file(config_file_name)
          require 'yaml'
          load YAML.safe_load(::File.read(config_file_name))
        end

        # Loads configuration from a Hash.
        def load(config_data)
          packages = (config_data['packages'] || []).map do |package|
            Package.new(package['path'], package['exclude'] || [])
          end
          Config.new config_data['name'], packages
        end
      end

      def initialize(name, packages = [])
        super name, packages || []
      end

      def to_h
        {
          name: name,
          packages: packages.map(&:to_h)
        }
      end
    end

    HOOK_DISABLE_KEY = 'AppMap::Hook.disable'

    class << self
      # Observe class loading and hook all methods which match the config.
      def hook(config = AppMap.configure)
        package_include_paths = config.packages.map(&:path)
        package_exclude_paths = config.packages.map do |pkg|
          pkg.exclude.map do |exclude|
            File.join(pkg.path, exclude)
          end
        end.flatten

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
          # by the fn. Otherwise there can be a stack oveflow.
          Thread.current[HOOK_DISABLE_KEY] = true
          begin
            fn.call
          ensure
            Thread.current[HOOK_DISABLE_KEY] = false
          end
        end

        TracePoint.trace(:end) do |tp|
          cls = tp.self

          instance_methods = cls.public_instance_methods(false)
          class_methods = cls.singleton_class.public_instance_methods(false) - instance_methods

          hook_method = lambda do |cls|
            lambda do |method_id|
              next if method_id.to_s =~ /_hooked_by_appmap$/

              method = cls.public_instance_method(method_id)
              location = method.source_location
              location_file, = location
              next unless location_file

              location_file = location_file[Dir.pwd.length + 1..-1] if location_file.index(Dir.pwd) == 0
              match = package_include_paths.find { |p| location_file.index(p) == 0 }
              match &&= !package_exclude_paths.find { |p| location_file.index(p) }
              next unless match

              disasm = RubyVM::InstructionSequence.disasm(method)
              # Skip methods that have no instruction sequence, as they are obviously trivial.
              next unless disasm

              defined_class, method_symbol = \
                if method.owner.singleton_class?
                  # Singleton class name is like: #<Class:<(.*)>>
                  class_name = method.owner.to_s['#<Class:<'.length-1..-2]
                  [ class_name, '.' ]
                else
                  [ method.owner.name, '#' ]
                end

              method_display_name = "#{defined_class}#{method_symbol}#{method.name}"
              # Don't try and trace the tracing method or there will be a stack overflow
              # in the defined hook method.
              next if method_display_name == "AppMap.tracing"

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
      end
    end
  end
end

# frozen_string_literal: true

module AppMap
  class Hook
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

        TracePoint.trace(:end) do |tp|
          cls = tp.self
          methods = cls.public_instance_methods(false)
          methods.map do |m|
            next if m.to_s =~ /_hooked_by_appmap$/

            method = cls.public_instance_method(m)
            location = method.source_location
            location_file, = location
            next unless location_file

            location_file = location_file[Dir.pwd.length + 1..-1] if location_file.index(Dir.pwd) == 0
            match = package_include_paths.find { |p| location_file.index(p) == 0 }
            match &&= !package_exclude_paths.find { |p| location_file.index(p) }
            next unless match

            owner_name, method_symbol = \
              if method.owner.singleton_class?
                require 'appmap/util'
                [ AppMap::Util.descendant_class(method.owner).name, '.' ]
              else
                [ method.owner.name, '#' ]
              end

            warn "AppMap: Hooking #{owner_name}#{method_symbol}#{method.name}"

            cls.alias_method "#{m}_hooked_by_appmap".to_sym, m
            cls.define_method m do |*args, &block|
              require 'appmap/trace/tracer'

              before_hook = lambda do
                call_event = AppMap::Trace::MethodCall.build_from_invocation(method, self, args)
                AppMap::Trace.tracers.record_event call_event
                [ call_event, Time.now ]
              end

              after_hook = lambda do |call_event, start_time, return_value|
                elapsed = Time.now - start_time
                return_event = AppMap::Trace::MethodReturn.build_from_invocation \
                  method, call_event.id, elapsed, return_value
                AppMap::Trace.tracers.record_event return_event
              end

              with_disabled_hook = lambda do |enabled, &fn|
                if enabled
                  # Don't hook functions such as to_s and inspect that might be called
                  # by the fn.
                  Thread.current[HOOK_DISABLE_KEY] = true
                  begin
                    fn.call
                  ensure
                    Thread.current[HOOK_DISABLE_KEY] = false
                  end
                end
              end

              hook_disabled = Thread.current[HOOK_DISABLE_KEY]
              enabled = true if !hook_disabled && AppMap::Trace.tracers.enabled?
              call_event, start_time = with_disabled_hook.call(enabled) do
                before_hook.call
              end
              return_value = nil
              begin
                return_value = send "#{m}_hooked_by_appmap", *args, &block
              ensure
                with_disabled_hook.call(enabled) do
                  after_hook.call(call_event, start_time, return_value)
                end
              end
            end
            location_file
          end
        end
      end
    end
  end
end

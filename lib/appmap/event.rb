# frozen_string_literal: true

module AppMap
  module Event
    @@id_counter = 0

    class << self
      # reset_id_counter is used by test cases to get consistent event ids.
      def reset_id_counter
        @@id_counter = 0
      end

      def next_id_counter
        @@id_counter += 1
      end
    end

    MethodEventStruct = Struct.new(:id, :event, :thread_id)

    class MethodEvent < MethodEventStruct
      LIMIT = 100

      class << self
        def build_from_invocation(me, event_type)
          me.id = AppMap::Event.next_id_counter
          me.event = event_type
          me.thread_id = Thread.current.object_id
        end

        # Gets a display string for a value. This is not meant to be a machine deserializable value.
        def display_string(value)
          return nil unless value

          value_string = custom_display_string(value) || default_display_string(value)

          (value_string||'')[0...LIMIT].encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
        end

        def object_properties(hash_like)
          hash = hash_like.to_h
          hash.keys.map do |key|
            {
              name: key,
              class: hash[key].class.name,
            }
          end
        rescue
          nil
        end

        protected

        # Heuristic for dynamically defined class whose name can be nil
        def best_class_name(value)
          value_cls = value.class
          while value_cls.name.nil?
            value_cls = value_cls.superclass
          end
          value_cls.name
        end

        def custom_display_string(value)
          case value
          when File
            "#{value.class}[path=#{value.path}]"
          when Net::HTTP
            "#{value.class}[#{value.address}:#{value.port}]"
          when Net::HTTPGenericRequest
            "#{value.class}[#{value.method} #{value.path}]"
          end
        rescue StandardError
          nil
        end

        def default_display_string(value)
          last_resort_string = lambda do
            warn "AppMap encountered an error inspecting a #{value.class.name}: #{$!.message}"
            '*Error inspecting variable*'
          end

          begin
            value.to_s
          rescue NoMethodError
            begin
              value.inspect
            rescue StandardError
              last_resort_string.call
            end
          rescue StandardError
            last_resort_string.call
          end
        end
      end

      protected

      def object_properties(hash_like)
        self.class.object_properties(hash_like)
      end
    end

    class MethodCall < MethodEvent
      attr_accessor :defined_class, :method_id, :path, :lineno, :parameters, :receiver, :static

      class << self
        def build_from_invocation(mc = MethodCall.new, defined_class, method, receiver, arguments)
          defined_class ||= 'Class'
          mc.tap do
            static = receiver.is_a?(Module)
            mc.defined_class = defined_class
            mc.method_id = method.name.to_s
            if method.source_location
              path = method.source_location[0]
              path = path[Dir.pwd.length + 1..-1] if path.index(Dir.pwd) == 0
              mc.path = path
              mc.lineno = method.source_location[1]
            else
              mc.path = [ defined_class, static ? '.' : '#', method.name ].join
            end

            # Check if the method has key parameters. If there are any they'll always be last.
            # If yes, then extract it from arguments.
            has_key = [[:dummy], *method.parameters].last.first.to_s.start_with?('key') && arguments[-1].is_a?(Hash)
            kwargs = has_key && arguments[-1].dup || {}

            mc.parameters = method.parameters.map.with_index do |method_param, idx|
              param_type, param_name = method_param
              param_name ||= 'arg'
              value = case param_type
                when :keyrest
                  kwargs
                when /^key/
                  kwargs.delete param_name
                when :rest
                  arguments[idx..(has_key ? -2 : -1)]
                else
                  arguments[idx]
                end
              {
                name: param_name,
                class: best_class_name(value),
                object_id: value.__id__,
                value: display_string(value),
                kind: param_type
              }
            end
            mc.receiver = {
              class: best_class_name(receiver),
              object_id: receiver.__id__,
              value: display_string(receiver)
            }
            mc.static = static
            MethodEvent.build_from_invocation(mc, :call)
          end
        end
      end

      def to_h
        super.tap do |h|
          h[:defined_class] = defined_class
          h[:method_id] = method_id
          h[:path] = path
          h[:lineno] = lineno
          h[:static] = static
          h[:parameters] = parameters
          h[:receiver] = receiver
          h.delete_if { |_, v| v.nil? }
        end
      end

      alias static? static
    end

    class MethodReturnIgnoreValue < MethodEvent
      attr_accessor :parent_id, :elapsed

      class << self
        def build_from_invocation(mr = MethodReturnIgnoreValue.new, parent_id, elapsed)
          mr.tap do |_|
            mr.parent_id = parent_id
            mr.elapsed = elapsed
            MethodEvent.build_from_invocation(mr, :return)
          end
        end
      end

      def to_h
        super.tap do |h|
          h[:parent_id] = parent_id
          h[:elapsed] = elapsed
        end
      end
    end

    class MethodReturn < MethodReturnIgnoreValue
      attr_accessor :return_value, :exceptions

      class << self
        def build_from_invocation(mr = MethodReturn.new, parent_id, elapsed, return_value, exception)
          mr.tap do |_|
            if return_value
              mr.return_value = {
                class: best_class_name(return_value),
                value: display_string(return_value),
                object_id: return_value.__id__
              }
            end
            if exception
              next_exception = exception
              exceptions = []
              while next_exception
                exception_backtrace = next_exception.backtrace_locations.try(:[], 0)
                exceptions << {
                  class: best_class_name(next_exception),
                  message: next_exception.message,
                  object_id: next_exception.__id__,
                  path: exception_backtrace&.path,
                  lineno: exception_backtrace&.lineno
                }.compact
                next_exception = next_exception.cause
              end

              mr.exceptions = exceptions
            end
            MethodReturnIgnoreValue.build_from_invocation(mr, parent_id, elapsed)
          end
        end
      end

      def to_h
        super.tap do |h|
          h[:return_value] = return_value if return_value
          h[:exceptions] = exceptions if exceptions
        end
      end
    end
  end
end

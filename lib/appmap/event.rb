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

    MethodEventStruct = Struct.new(:id, :event, :defined_class, :method_id, :path, :lineno, :static, :thread_id)

    class MethodEvent < MethodEventStruct
      LIMIT = 100

      class << self
        def build_from_invocation(me, event_type, defined_class, method)
          singleton = method.owner.singleton_class?

          me.id = AppMap::Event.next_id_counter
          me.event = event_type
          me.defined_class = defined_class
          me.method_id = method.name.to_s
          path = method.source_location[0]
          path = path[Dir.pwd.length + 1..-1] if path.index(Dir.pwd) == 0
          me.path = path
          me.lineno = method.source_location[1]
          me.static = singleton
          me.thread_id = Thread.current.object_id
        end

        # Gets a display string for a value. This is not meant to be a machine deserializable value.
        def display_string(value)
          return nil unless value

          last_resort_string = lambda do
            warn "AppMap encountered an error inspecting a #{value.class.name}: #{$!.message}"
            '*Error inspecting variable*'
          end

          value_string = \
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

          (value_string||'')[0...LIMIT].encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
        end
      end

      alias static? static
    end

    class MethodCall < MethodEvent
      attr_accessor :parameters, :receiver

      class << self
        def build_from_invocation(mc = MethodCall.new, defined_class, method, receiver, arguments)
          mc.tap do
            mc.parameters = method.parameters.map.with_index do |method_param, idx|
              param_type, param_name = method_param
              param_name ||= 'arg'
              value = arguments[idx]
              {
                name: param_name,
                class: value.class.name,
                object_id: value.__id__,
                value: display_string(value),
                kind: param_type
              }
            end
            mc.receiver = {
              class: receiver.class.name,
              object_id: receiver.__id__,
              value: display_string(receiver)
            }
            MethodEvent.build_from_invocation(mc, :call, defined_class, method)
          end
        end
      end

      def to_h
        super.tap do |h|
          h[:parameters] = parameters
          h[:receiver] = receiver
        end
      end
    end

    class MethodReturnIgnoreValue < MethodEvent
      attr_accessor :parent_id, :elapsed

      class << self
        def build_from_invocation(mr = MethodReturnIgnoreValue.new, defined_class, method, parent_id, elapsed)
          mr.tap do |_|
            mr.parent_id = parent_id
            mr.elapsed = elapsed
            MethodEvent.build_from_invocation(mr, :return, defined_class, method)
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
        def build_from_invocation(mr = MethodReturn.new, defined_class, method, parent_id, elapsed, return_value, exception)
          mr.tap do |_|
            if return_value
              mr.return_value = {
                class: return_value.class.name,
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
                  class: next_exception.class.name,
                  message: next_exception.message,
                  object_id: next_exception.__id__,
                  path: exception_backtrace&.path,
                  lineno: exception_backtrace&.lineno
                }.compact
                next_exception = next_exception.cause
              end

              mr.exceptions = exceptions
            end
            MethodReturnIgnoreValue.build_from_invocation(mr, defined_class, method, parent_id, elapsed)
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

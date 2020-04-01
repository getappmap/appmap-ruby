# frozen_string_literal: true

module AppMap
  module Trace
    MethodEventStruct =
      Struct.new(:id, :event, :defined_class, :method_id, :path, :lineno, :static, :thread_id)

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

    class Tracers
      def initialize
        @tracers = []
      end

      def empty?
        @tracers.empty?
      end

      # TODO: remove functions argument
      def trace(enable: true)
        AppMap::Trace::Tracer.new.tap do |tracer|
          @tracers << tracer
          tracer.enable if enable
        end
      end 

      def enabled?
        @tracers.any?(&:enabled?)
      end

      def record_event(event, method: nil)
        @tracers.each do |tracer|
          tracer.record_event(event, method: method)
        end
      end

      def delete(tracer)
        return unless @tracers.member?(tracer)

        @tracers.delete(tracer)
        tracer.disable
      end
    end

    class << self
      def tracers
        @tracers ||= Tracers.new
      end
    end

    class MethodEvent < MethodEventStruct
      LIMIT = 100

      class << self
        def build_from_invocation(me, event_type, method)
          singleton = method.owner.singleton_class?

          require 'appmap/util'

          me.id = AppMap::Trace.next_id_counter
          me.event = event_type
          me.defined_class = singleton ? AppMap::Util.descendant_class(method.owner).name : method.owner.name
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
        def build_from_invocation(mc = MethodCall.new, method, receiver, arguments)
          mc.tap do
            mc.parameters = method.parameters.map.with_index do |method_param, idx|
              param_type, param_name = method_param
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
            MethodEvent.build_from_invocation(mc, :call, method)
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
        def build_from_invocation(mr = MethodReturnIgnoreValue.new, method, parent_id, elapsed)
          mr.tap do |_|
            mr.parent_id = parent_id
            mr.elapsed = elapsed
            MethodEvent.build_from_invocation(mr, :return, method)
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
      attr_accessor :return_value

      class << self
        def build_from_invocation(mr = MethodReturn.new, method, parent_id, elapsed, return_value)
          mr.tap do |_|
            mr.return_value = {
              class: return_value.class.name,
              value: display_string(return_value),
              object_id: return_value.__id__
            }
            MethodReturnIgnoreValue.build_from_invocation(mr, method, parent_id, elapsed)
          end
        end
      end

      def to_h
        super.tap do |h|
          h[:return_value] = return_value
        end
      end
    end

    class Tracer
      # Records the events which happen in a program.
      def initialize
        @events = []
        @methods = Set.new
        @enabled = false
      end

      def enable
        @enabled = true
      end

      def enabled?
        @enabled
      end

      # Private function. Use AppMap.tracers#delete.
      def disable # :nodoc:
        @enabled = false
      end

      # Record a program execution event.
      #
      # The event should be one of the MethodEvent subclasses.
      def record_event(event, method: nil)
        return unless @enabled

        @events << event
        @methods << method if method
      end

      # Gets a unique list of the methods that were invoked by the program.
      def event_methods
        @methods.to_a
      end

      # Whether there is an event available for processing.
      def event?
        !@events.empty?
      end

      # Gets the next available event, if any.
      def next_event
        @events.shift
      end
    end
  end
end

module AppMap
  module Trace
    MethodEventStruct =
      Struct.new(:id, :event, :defined_class, :method_id, :path, :lineno, :static, :thread_id,
                 :self, :parameters, :return_value)

    class << self
      def tracer
        @tracer || raise('No global tracer has been configured')
      end

      attr_writer :tracer
    end

    # @appmap
    class MethodEvent < MethodEventStruct
      LIMIT = 100

      COUNTER_LOCK = Mutex.new # :nodoc:
      @@id_counter = 0

      class << self
        # Build a new instance from a TracePoint.
        def build_from_tracepoint(me, tp, path)
          me.id = next_id
          me.event = tp.event

          if tp.defined_class.singleton_class?
            me.defined_class = (tp.self.is_a?(Class) || tp.self.is_a?(Module)) ? tp.self.name : tp.self.class.name
          else
            me.defined_class = tp.defined_class.name
          end

          me.method_id = tp.method_id
          me.path = path
          me.lineno = tp.lineno
          me.static = tp.defined_class.name.nil?
          me.thread_id = Thread.current.object_id
        end

        # Gets the next serial id.
        #
        # This method is thread-safe.
        # @appmap
        def next_id
          COUNTER_LOCK.synchronize do
            @@id_counter += 1
          end
        end

        # Gets a hash containing describing the current value of self.
        def inspect_self(tp)
          {
            class: tp.self.class.name,
            value: display_string(tp.self),
            object_id: tp.self.object_id
          }
        end

        # Gets a display string for a value. This is not meant to be a machine deserializable value.
        def display_string(value)
          return nil unless value

          begin
            value.to_s[0...LIMIT].encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
          rescue StandardError
            warn $!.message
            '*Error inspecting variable*'
          end
        end
      end

      alias static? static
    end

    # @appmap
    class MethodCall < MethodEvent
      class << self
        # @appmap
        def build_from_tracepoint(mc = MethodCall.new, tp, path)
          mc.tap do |_|
            mc.self = inspect_self(tp)
            mc.parameters = collect_parameters(tp)
            MethodEvent.build_from_tracepoint(mc, tp, path)
          end
        end

        def collect_parameters(tp)
          m = tp.self.method(tp.method_id) rescue nil
          # 'method' method may be overridden and hidden
          return {} unless m

          m.parameters.each_with_object({}) do |pinfo, memo|
            kind, key = pinfo
            begin
              value = tp.binding.eval(key.to_s)
            rescue NameError, ArgumentError
            end
            memo[key] = {
              class: value.class.name,
              value: display_string(value),
              object_id: value.object_id
            }
          end
        end
      end

      # @appmap
      def initialize(*args)
        super
      end

      def to_h
        super.tap do |h|
          h.delete(:return_value)
          h.delete(:parent_id)
          h.delete(:elapsed)
        end
      end
    end

    # @appmap
    class MethodReturn < MethodEvent
      attr_accessor :parent_id, :elapsed

      class << self
        # @appmap
        def build_from_tracepoint(mr = MethodReturn.new, tp, path, parent_id, elapsed)
          mr.tap do |_|
            mr.parent_id = parent_id
            mr.elapsed = elapsed
            mr.return_value = {
              class: tp.return_value.class.name,
              value: display_string(tp.return_value),
              object_id: tp.return_value.object_id
            }
            MethodEvent.build_from_tracepoint(mr, tp, path)
          end
        end
      end

      # @appmap
      def initialize(*args)
        super
      end

      def to_h
        super.tap do |h|
          h.delete(:self)
          h.delete(:parameters)
          h[:parent_id] = parent_id
          h[:elapsed] = elapsed
        end
      end
    end

    # Processes a series of calls into recorded events.
    # Each call to the handle should provide a TracePoint (or duck-typed object) as the argument.
    # On each call, a MethodEvent is constructed according to the nature of the TracePoint, and then
    # stored using the record_event method.
    # @appmap
    class TracePointHandler
      attr_accessor :call_constructor, :return_constructor

      # @appmap
      def initialize(tracer)
        @pwd = Dir.pwd
        @tracer = tracer
        @call_stack = Hash.new { |h, k| h[k] = [] }
        @call_constructor = MethodCall.method(:build_from_tracepoint)
        @return_constructor = MethodReturn.method(:build_from_tracepoint)
      end

      # @appmap
      def handle(tp)
        # Absoute paths which are within the current working directory are normalized
        # to be relative paths.
        path = tp.path
        if path.index(@pwd) == 0
          path = path[@pwd.length+1..-1]
        end

        method_event = if tp.event == :call && @tracer.break_on_line?(path, tp.lineno)
                         @call_constructor.call(tp, path).tap do |c|
                           @call_stack[Thread.current.object_id] << [ tp.defined_class, tp.method_id, c.id, Time.now ]
                         end
                       elsif (c = @call_stack[Thread.current.object_id].last) &&
                             c[0] == tp.defined_class &&
                             c[1] == tp.method_id
                         @call_stack[Thread.current.object_id].pop
                         @return_constructor.call(tp, path, c[2], Time.now - c[3])
                       end

        @tracer.record_event method_event if method_event

        method_event
      rescue
        puts $!.message
        puts $!.backtrace.join("\n")
      end
    end

    # @appmap
    class Tracer
      class << self
        # Trace program execution using a TracePoint hook. As methods are called and returned from,
        # the events are recorded via Tracer#record_event.
        # @appmap
        def trace(tracer)
          handler = TracePointHandler.new(tracer)
          TracePoint.trace(:call, :return, &handler.method(:handle))
        end
      end

      # Trace a specified set of methods.
      #
      # methods Array of AppMap::Feature::Method.
      # @appmap
      def initialize(methods)
        @methods = methods

        @methods_by_location = methods.each_with_object({}) do |m, memo|
          path, lineno = m.location.split(':', 2)
          memo[path] ||= {}
          memo[path][lineno.to_i] = m
          memo
        end

        @events_mutex = Mutex.new
        @events = []
      end

      # Whether the indicated file path and lineno is a breakpoint on which
      # execution should interrupted.
      # @appmap
      def break_on_line?(path, lineno)
        (methods_by_path = @methods_by_location[path]) && methods_by_path[lineno]
      end

      # Record a program execution event.
      #
      # The event should be one of the MethodEvent subclasses.
      #
      # This method is thread-safe.
      # @appmap
      def record_event(event)
        @events_mutex.synchronize do
          @events << event
        end
      end

      # Whether there is an event available for processing.
      #
      # This method is thread-safe.
      def event?
        @events_mutex.synchronize do
          !@events.empty?
        end
      end

      # Gets the next available event, if any.
      #
      # This method is thread-safe.
      def next_event
        @events_mutex.synchronize do
          @events.shift
        end
      end
    end
  end
end

module AppMap
  module Trace
    MethodEventStruct = Struct.new(:id, :event, :defined_class, :method_id, :static, :thread_id, :variables)

    class MethodEvent < MethodEventStruct
      LIMIT = 100

      COUNTER_LOCK = Mutex.new # :nodoc:
      @@id_counter = 0

      class << self
        # Gets the next serial id.
        #
        # This method is thread-safe.
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
            value.to_s[0...LIMIT]
          rescue StandardError
            '*Error inspecting variable*'
          end
        end
      end

      alias static? static

      # Build a new instance from a TracePoint.
      def initialize(tp)
        self.id = self.class.next_id
        self.event = tp.event

        if tp.defined_class.name
          self.defined_class = tp.defined_class.name
        else
          raise "Expecting <Class:[class-name]> for static method call, got #{tp.defined_class}" \
            unless (md = tp.defined_class.to_s.match(/^#<Class:(.*)>$/))
          self.defined_class = md[1]
        end

        self.method_id = tp.method_id
        self.static = tp.defined_class.name.nil?
        self.thread_id = Thread.current.object_id
      end
    end

    class MethodCall < MethodEvent
      class << self
        def collect_variables(tp)
          m = tp.self.method(tp.method_id)
          lv = m.parameters.each_with_object({}) do |pinfo, memo|
            kind, key = pinfo
            begin
              value = tp.binding.eval(key.to_s)
            rescue NameError
            end
            memo[key] = {
              class: value.class.name,
              value: display_string(value),
              object_id: value.object_id
            }
          end
          {
            self: inspect_self(tp),
            variables: lv
          }
        end
      end

      def initialize(tp)
        super

        self.variables = MethodCall.collect_variables(tp)
      end
    end

    class MethodReturn < MethodEvent
      attr_reader :parent_id, :elapsed

      def initialize(tp, parent_id, elapsed)
        super(tp)

        @parent_id = parent_id
        @elapsed = elapsed
        self.variables = {
          self: self.class.inspect_self(tp),
          return_value: {
            class: tp.return_value.class.name,
            value: self.class.display_string(tp.return_value),
            object_id: tp.return_value.object_id
          }
        }
      end

      def to_h
        super.tap do |h|
          h[:parent_id] = parent_id
          h[:elapsed] = elapsed
        end
      end
    end

    class Tracer
      class << self
        # Trace program execution using a TracePoint hook. As methods are called and returned from,
        # the events are recorded via Tracer#record_event.
        def trace(tracer)
          call_stack = Hash.new { |h, k| h[k] = [] }
          TracePoint.trace(:call, :return) do |tp|
            # In order to make this as quick as possible, we lookup the TracePoint by
            # file path and line number in a pre-populated Hash.
            #
            # If the user wants to trace this event, the data is copied from the TracePoint
            # into a struct and then pushed onto a queue for processing by another thread so that
            # the program can continue in the meantime.
            method_event = if tp.event == :call && tracer.break_on_line?(tp.path, tp.lineno)
              AppMap::Trace::MethodCall.new(tp).tap do |c|
                call_stack[Thread.current.object_id] << [ tp.defined_class, tp.method_id, c.id, Time.now ]
              end
            elsif (c = call_stack[Thread.current.object_id].last) &&
              c[0] == tp.defined_class &&
              c[1] == tp.method_id
              call_stack[Thread.current.object_id].pop
              AppMap::Trace::MethodReturn.new(tp, c[2], Time.now - c[3])
            end

            if method_event
              tracer.record_event method_event
            end
          end
        end
      end

      # Trace a specified set of methods.
      #
      # methods Array of AppMap::Annotation::Method.
      def initialize(methods)
        @methods = methods

        @methods_by_location = methods.each_with_object({}) do |m, memo|
          path, lineno = m.location.split(':', 2)
          path = File.absolute_path(path)
          memo[path] ||= {}
          memo[path][lineno.to_i] = m
          memo
        end

        @events_mutex = Mutex.new
        @events = []
      end

      # Whether the indicated file path and lineno is a breakpoint on which
      # execution should interrupted.
      def break_on_line?(path, lineno)
        (methods_by_path = @methods_by_location[path]) && methods_by_path[lineno]
      end

      # Record a program execution event.
      #
      # The event should be one of the MethodEvent subclasses.
      #
      # This method is thread-safe.
      def record_event(event)
        @events_mutex.synchronize do
          @events << event
        end
      end

      # Whether there is an event available for processing.
      #
      # This method is thread-safe.
      def has_event?
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

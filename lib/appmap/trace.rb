# frozen_string_literal: true

module AppMap
  module Trace
    ScopedMethod = Struct.new(:defined_class, :method, :static)

    class Tracing
      def initialize
        @Tracing = []
      end

      def empty?
        @Tracing.empty?
      end

      def trace(enable: true)
        Tracer.new.tap do |tracer|
          @Tracing << tracer
          tracer.enable if enable
        end
      end

      def enabled?
        @Tracing.any?(&:enabled?)
      end

      def record_event(event, defined_class: nil, method: nil)
        @Tracing.each do |tracer|
          tracer.record_event(event, defined_class: defined_class, method: method)
        end
      end

      def delete(tracer)
        return unless @Tracing.member?(tracer)

        @Tracing.delete(tracer)
        tracer.disable
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

    # Private function. Use AppMap.tracing#delete.
    def disable # :nodoc:
      @enabled = false
    end

    # Record a program execution event.
    #
    # The event should be one of the MethodEvent subclasses.
    def record_event(event, defined_class: nil, method: nil)
      return unless @enabled

      @events << event
      @methods << Trace::ScopedMethod.new(defined_class, method, event.static) if (defined_class && method && event.event == :call)
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

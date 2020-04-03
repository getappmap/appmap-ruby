# frozen_string_literal: true

module AppMap
  module Trace
    class Tracers
      def initialize
        @tracers = []
      end

      def empty?
        @tracers.empty?
      end

      def trace(enable: true)
        Tracer.new.tap do |tracer|
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

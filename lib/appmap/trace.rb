# frozen_string_literal: true

module AppMap
  module Trace
    class ScopedMethod < SimpleDelegator
      attr_reader :package, :defined_class, :static

      def initialize(package, defined_class, method, static)
        @package = package
        @defined_class = defined_class
        @static = static
        super(method)
      end
    end

    class Tracing
      def initialize
        @tracing = []
      end

      def empty?
        @tracing.empty?
      end

      def trace(enable: true)
        Tracer.new.tap do |tracer|
          @tracing << tracer
          tracer.enable if enable
        end
      end

      def enabled?
        @tracing.any?(&:enabled?)
      end

      def record_event(event, package: nil, defined_class: nil, method: nil)
        @tracing.each do |tracer|
          tracer.record_event(event, package: package, defined_class: defined_class, method: method)
        end
      end

      def delete(tracer)
        return unless @tracing.member?(tracer)

        @tracing.delete(tracer)
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
    def record_event(event, package: nil, defined_class: nil, method: nil)
      return unless @enabled

      @events << event
      @methods << Trace::ScopedMethod.new(package, defined_class, method, event.static) \
        if package && defined_class && method && (event.event == :call)
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

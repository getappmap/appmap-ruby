# frozen_string_literal: true

require 'delegate'

module AppMap
  module Trace
    class RubyMethod < SimpleDelegator
      attr_reader :class_name, :static

      def initialize(package, class_name, method, static)
        super(method)

        @package = package
        @class_name = class_name
        @method = method
        @static = static
      end

      def source_location
        @method.source_location
      end

      def comment
        @method.comment
      rescue MethodSource::SourceNotFoundError
        nil
      end

      def package
        @package.name
      end

      def name
        @method.name
      end

      def labels
        @package.labels
      end
    end

    class Tracing
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

      def last_package_for_current_thread
        @tracers.first&.last_package_for_current_thread
      end

      def record_event(event, package: nil, defined_class: nil, method: nil)
        @tracers.each do |tracer|
          tracer.record_event(event, package: package, defined_class: defined_class, method: method)
        end
      end

      def record_method(method)
        @tracers.each do |tracer|
          tracer.record_method(method)
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
      @last_package_for_thread = {}
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

      @last_package_for_thread[Thread.current.object_id] = package if package
      @events << event
      static = event.static if event.respond_to?(:static)
      record_method Trace::RubyMethod.new(package, defined_class, method, static) \
        if package && defined_class && method && (event.event == :call)
    end

    # +method+ should be duck-typed to respond to the following:
    # * package
    # * defined_class
    # * name
    # * static
    # * comment
    # * labels
    # * source_location
    def record_method(method)
      @methods << method
    end

    # Gets the last package which was observed on the current thread.
    def last_package_for_current_thread
      @last_package_for_thread[Thread.current.object_id]
    end

    # Gets a unique list of the methods that were invoked by the program.
    def event_methods
      @methods.to_a
    end

    # Whether there is an event available for processing.
    def event?
      !@events.empty? && @events.first.ready?
    end

    # Gets the next available event, if any.
    def next_event
      @events.shift if event?
    end
  end
end

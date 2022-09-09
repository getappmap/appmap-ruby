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

      # =======================================================================
      # The following appmap_ functions were copied from
      # https://github.com/banister/method_source under the license:
      #
      #       MIT License

      # Copyright (c) 2011 John Mair (banisterfiend)

      # Permission is hereby granted, free of charge, to any person obtaining
      # a copy of this software and associated documentation files (the
      # 'Software'), to deal in the Software without restriction, including
      # without limitation the rights to use, copy, modify, merge, publish,
      # distribute, sublicense, and/or sell copies of the Software, and to
      # permit persons to whom the Software is furnished to do so, subject to
      # the following conditions:

      # The above copyright notice and this permission notice shall be
      # included in all copies or substantial portions of the Software.

      # THE SOFTWARE IS PROVIDED 'AS IS', WITHOUT WARRANTY OF ANY KIND,
      # EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
      # MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT.
      # IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY
      # CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT,
      # TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE
      # SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

      class SourceNotFoundError < StandardError; end

      def appmap_extract_last_comment(lines)
        buffer = []

        lines.reverse_each do |line|
          # Add any line that is a valid ruby comment, and stop as
          # soon as we hit a non comment line.
          if (line =~ /^\s*#/) || (line =~ /^\s*$/)
            buffer.append(line.lstrip)
          else
            break
          end
        end

        buffer.reverse.join()
      end

      def appmap_comment_describing(file, line_number)
        lines = file.is_a?(Array) ? file : file.each_line.to_a

        appmap_extract_last_comment(lines[0..(line_number - 2)])
      end

      def appmap_lines_for(file_name, name=nil)
        @lines_for_file ||= {}
        @lines_for_file[file_name] ||= File.readlines(file_name)
      rescue Errno::ENOENT => e
        raise AppMap::Trace::RubyMethod::SourceNotFoundError, "Could not load source for #{name}: #{e.message}"
      end

      def appmap_comment_helper(source_location, name=nil)
        raise AppMap::Trace::RubyMethod::SourceNotFoundError, "Could not locate source for #{name}!" unless source_location
        file, line = *source_location

        appmap_comment_describing(appmap_lines_for(file), line)
      end

      def comment
        # use AppMap's optimization in appmap_extract_last_comment to
        # extract comments...
        appmap_comment_helper(source_location, defined?(name) ? name : inspect)
        # ... instead of use MethodSource which hasn't merged
        # https://github.com/banister/method_source/pull/78.  When/if
        # this pr gets merged, AppMap's optimization can be removed
        # and the previous implementation of "def comment" can be uncommented:
      rescue AppMap::Trace::RubyMethod::SourceNotFoundError, Errno::EINVAL
        nil
      end
      # =======================================================================

      # def comment
      #   @method.comment
      # rescue MethodSource::SourceNotFoundError, Errno::EINVAL
      #   nil
      # end

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

      def trace(enable: true, thread: nil)
        Tracer.new(thread_id: thread&.object_id).tap do |tracer|
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
        @tracers.select { |tracer| tracer.thread_id.nil? || tracer.thread_id === event.thread_id }.each do |tracer|
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

  class StackPrinter
    class << self
      def enabled?
        ENV['APPMAP_PRINT_STACKS'] == 'true'
      end

      def depth
        (ENV['APPMAP_STACK_DEPTH'] || 20).to_i
      end
    end

    def initialize
      @@stacks ||= Hash.new
    end

    def record(event)
      stack = caller.select { |line| !line.index('/lib/appmap/') }[0...StackPrinter.depth].join("\n  ")
      stack_hash = Digest::SHA256.hexdigest(stack)
      unless @@stacks[stack_hash]
        @@stacks[stack_hash] = stack
        puts
        puts 'Event: ' + event.to_h.map { |k, v| [ "#{k}: #{v}" ] }.join(", ")
        puts '  ' + stack
        puts
      end
    end
  end

  class Tracer
    attr_accessor :stacks
    attr_reader   :thread_id, :events

    # Records the events which happen in a program.
    def initialize(thread_id: nil)
      @events = []
      @last_package_for_thread = {}
      @methods = Set.new
      @stack_printer = StackPrinter.new if StackPrinter.enabled?
      @enabled = false
      @thread_id = thread_id
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

      raise "Expected event in thread #{@thread_id}, got #{event.thread_id}" if @thread_id && @thread_id != event.thread_id 

      @stack_printer.record(event) if @stack_printer
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

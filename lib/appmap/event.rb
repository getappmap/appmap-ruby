# frozen_string_literal: true

require 'weakref'
require_relative './value_inspector'

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
      extend ValueInspector

      MAX_ARRAY_ENUMERATION = 10
      MAX_HASH_ENUMERATION = 10
      MAX_STRING_LENGTH = 100

      class << self
        def build_from_invocation(event_type, event:)
          event.id = AppMap::Event.next_id_counter
          event.event = event_type
          event.thread_id = Thread.current.object_id
        end

        # Gets a display string for a value. This is not meant to be a machine deserializable value.
        def display_string(value)
          return nil if value.equal?(nil)

          # With setting APPMAP_PROFILE_DISPLAY_STRING, stringifying this class is shown to take 9 seconds(!) of a 17 second test run.
          return nil if best_class_name(value) == 'ActiveSupport::Callbacks::Filters::Environment'

          if @times.nil? && ENV['APPMAP_PROFILE_DISPLAY_STRING'] == 'true'
            @times = Hash.new {|memo,key| memo[key] = 0}
            Thread.new do
              sleep 0.5
              while true
                warn @times.to_a.sort{|a,b| b[1] <=> a[1]}[0..9].join("\n")
                sleep 3
              end
            end
          end

          start = Time.now
          value_string, final = custom_display_string(value) || default_display_string(value)

          if @times
            elapsed = Time.now - start
            @times[best_class_name(value)] += elapsed
          end

          final ? value_string : encode_display_string(value_string)
        end

        def add_size(param, value)
          size = ValueInspector.detect_size(value)
          param[:size] = size if size
        end

        def add_schema(param, value)
          ValueInspector.detect_schema(value, type_info: param)
        end

        def encode_display_string(value)
          (value||'')[0...MAX_STRING_LENGTH].encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
        end

        def custom_display_string(value)
          case value
          when NilClass, TrueClass, FalseClass, Numeric, Time, Date
            [ value.to_s, true ]
          when Symbol
            [ ":#{value}", true ]
          when String
            result = value[0...MAX_STRING_LENGTH].encode('utf-8', invalid: :replace, undef: :replace, replace: '_')
            result << " (...#{value.length - MAX_STRING_LENGTH} more characters)" if value.length > MAX_STRING_LENGTH
            [ result, true ]
          when Array
            result = value[0...MAX_ARRAY_ENUMERATION].map{|v| display_string(v)}.join(', ')
            result << " (...#{value.length - MAX_ARRAY_ENUMERATION} more items)" if value.length > MAX_ARRAY_ENUMERATION
            [ [ '[', result, ']' ].join, true ]
          when Hash
            result = value.keys[0...MAX_HASH_ENUMERATION].map{|key| "#{display_string(key)}=>#{display_string(value[key])}"}.join(', ')
            result << " (...#{value.size - MAX_HASH_ENUMERATION} more entries)" if value.size > MAX_HASH_ENUMERATION
            [ [ '{', result, '}' ].join, true ]
          when File
            [ "#{value.class}[path=#{value.path}]", true ]
          when Net::HTTP
            [ "#{value.class}[#{value.address}:#{value.port}]", true ]
          when Net::HTTPGenericRequest
            [ "#{value.class}[#{value.method} #{value.path}]", true ]
          end
        rescue StandardError
          nil
        end

        def default_display_string(value)
          return nil if ENV['APPMAP_OBJECT_STRING'] == 'false'

          last_resort_string = lambda do
            warn "AppMap encountered an error inspecting a #{value.class.name}: #{$!.message}"
            '*Error inspecting variable*'
          end

          begin
            value.to_s
          rescue NoMethodError
            begin
              value.inspect
            rescue
              last_resort_string.call
            end
          rescue WeakRef::RefError
            nil
          rescue
            last_resort_string.call
          end
        end
      end
      
      # An event may be partially constructed, and then completed at a later time. When the event
      # is only partially constructed, it's not ready for serialization to the AppMap file. 
      # 
      # @return false until the event is fully constructed and available.
      def ready?
        true
      end

      protected

      def object_properties(hash_like)
        self.class.object_properties(hash_like)
      end
    end

    class MethodCall < MethodEvent
      attr_accessor :defined_class, :method_id, :path, :lineno, :parameters, :receiver, :static

      MethodMetadata = Struct.new(:defined_class, :method_id, :path, :lineno, :static)

      @@method_metadata = {}

      class << self
        private

        def method_metadata(defined_class, method, receiver)
          result = @@method_metadata[method]
          return result if result

          result = MethodMetadata.new
          result.static = receiver.is_a?(Module)
          result.defined_class = defined_class
          result.method_id = method.name.to_s
          if method.source_location
            path = method.source_location[0]
            path = path[Dir.pwd.length + 1..-1] if path.index(Dir.pwd) == 0
            result.path = path
            result.lineno = method.source_location[1]
          else
            result.path = [ defined_class, result.static ? '.' : '#', method.name ].join
          end
          @@method_metadata[method] = result
        end

        public

        def build_from_invocation(defined_class, method, receiver, arguments, parameters: method.parameters, event: MethodCall.new)
          event ||= MethodCall.new
          defined_class ||= 'Class'

          event.tap do
            metadata = method_metadata(defined_class, method, receiver)

            event.defined_class = metadata.defined_class
            event.method_id = metadata.method_id
            event.path = metadata.path
            event.lineno = metadata.lineno
            event.static = metadata.static

            # Check if the method has key parameters. If there are any they'll always be last.
            # If yes, then extract it from arguments.
            has_key = [[:dummy], *parameters].last.first.to_s.start_with?('key') && arguments[-1].is_a?(Hash)
            kwargs = has_key && arguments[-1].dup || {}

            event.parameters = parameters.map.with_index do |method_param, idx|
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
              }.tap do |param|
                add_size param, value
              end
            end
            event.receiver = {
              class: best_class_name(receiver),
              object_id: receiver.__id__,
              value: display_string(receiver)
            }

            MethodEvent.build_from_invocation(:call, event: event)
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
      attr_accessor :parent_id, :elapsed, :elapsed_instrumentation

      class << self
        def build_from_invocation(parent_id, elapsed: nil, event: MethodReturnIgnoreValue.new)
          event ||= MethodReturnIgnoreValue.new
          event.tap do |_|
            event.parent_id = parent_id
            event.elapsed = elapsed
            MethodEvent.build_from_invocation(:return, event: event)
          end
        end
      end

      def to_h
        super.tap do |h|
          h[:parent_id] = parent_id
          h[:elapsed] = elapsed if elapsed
          h[:elapsed_instrumentation] = elapsed_instrumentation if elapsed_instrumentation
        end
      end
    end

    class MethodReturn < MethodReturnIgnoreValue
      attr_accessor :return_value, :exceptions

      class << self
        def build_from_invocation(parent_id, return_value, exception, elapsed: nil, event: MethodReturn.new, parameter_schema: false)
          event ||= MethodReturn.new
          event.tap do |_|
            if return_value
              event.return_value = {
                class: best_class_name(return_value),
                value: display_string(return_value),
                object_id: return_value.__id__
              }.tap do |param|
                add_size param, return_value
                add_schema param, return_value if parameter_schema && !exception
              end
            end
            if exception
              next_exception = exception
              exceptions = []
              while next_exception
                exception_backtrace = AppMap::Util.try(next_exception.backtrace_locations, :[], 0)
                exceptions << {
                  class: best_class_name(next_exception),
                  message: display_string(next_exception.message),
                  object_id: next_exception.__id__,
                  path: exception_backtrace&.path,
                  lineno: exception_backtrace&.lineno
                }.compact
                next_exception = next_exception.cause
              end

              event.exceptions = exceptions
            end
            MethodReturnIgnoreValue.build_from_invocation(parent_id, elapsed: elapsed, event: event)
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

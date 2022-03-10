# frozen_string_literal: true

require 'appmap/event'

include AppMap
module AppMap
  module Handler
    module Strings # It's not a great idea to call a module 'String'
      module StringEvent
        @@string_counter = 0
      
        class << self
          # reset_string_count is used by test cases to get consistent event ids.
          def reset_string_counter
            @@string_counter = 0
          end
      
          def next_string_counter
            @@string_counter += 1
          end
        end
      
        def record?
          false
        end
      end
      
      class StringCallEvent < Event::MethodEventStruct
        include StringEvent
      
        def initialize(method_name, receiver, args)
          super receiver.object_id, :call, Thread.current.object_id
      
          @method_id = method_name.to_s
          @args = args.filter { |arg| arg.is_a?(String) }.map(&:object_id)
        end
      
        def to_h
          {
            id: id,
            event: event,
            method_id: @method_id,
            args: @args,
          }
        end
      end
      
      class StringReturnEvent < Event::MethodEventStruct
        include StringEvent
      
        attr_accessor :parent_id, :return_value
      
        def initialize(parent_id, return_value)
          super parent_id, :return, Thread.current.object_id
      
          @return_value = return_value.object_id
        end
      
      
        def to_h
          {
            id: id,
            event: event,
            return_value: @return_value
          }
        end
      end
            
      class << self
        def handle_call(defined_class, hook_method, receiver, args)
          StringCallEvent.new(hook_method.name, receiver, args).tap do |event|
            AppMap.tracing.record_string_event(event)
          end
        end

        def handle_return(call_event_id, elapsed, return_value, exception)
          unless exception
            return_value = [ return_value ] unless return_value.is_a?(Array)
            return_value.select { |value| value.is_a?(String) }.map do |value|
              StringReturnEvent.new(call_event_id, value).tap do |event|
                AppMap.tracing.record_string_event(event)
              end
            end
          end
        end
      end
    end
  end
end

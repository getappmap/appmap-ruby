# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Rails
    module ActionHandler
      Context = Struct.new(:id, :start_time)

      module ContextKey
        def context_key
          "#{HTTPServerRequest.name}#call"
        end
      end

      class HTTPServerRequest
        include ContextKey

        class Call < AppMap::Event::MethodCall
          attr_accessor :payload

          def initialize(payload)
            super AppMap::Event.next_id_counter, :call, Thread.current.object_id

            self.payload = payload
          end

          def to_h
            super.tap do |h|
              h[:http_server_request] = {
                request_method: payload[:method],
                path_info: payload[:path]
              }

              params = payload[:params]
              h[:message] = params.keys.map do |key|
                val = params[key]
                {
                  name: key,
                  class: val.class.name,
                  value: self.class.display_string(val),
                  object_id: val.__id__
                }
              end
            end
          end
        end

        def call(_, started, finished, _, payload) # (name, started, finished, unique_id, payload)
          event = Call.new(payload)
          Thread.current[context_key] = Context.new(event.id, Time.now)
          AppMap.tracing.record_event(event)
        end
      end

      class HTTPServerResponse
        include ContextKey

        class Call < AppMap::Event::MethodReturnIgnoreValue
          attr_accessor :payload

          def initialize(payload, parent_id, elapsed)
            super AppMap::Event.next_id_counter, :return, Thread.current.object_id

            self.payload = payload
            self.parent_id = parent_id
            self.elapsed = elapsed
          end

          def to_h
            super.tap do |h|
              h[:http_server_response] = {
                status: payload[:status]
              }
            end
          end
        end

        def call(_, started, finished, _, payload) # (name, started, finished, unique_id, payload)
          return unless Thread.current[context_key]

          context = Thread.current[context_key]
          Thread.current[context_key] = nil

          event = Call.new(payload, context.id, Time.now - context.start_time)
          AppMap.tracing.record_event(event)
        end
      end
    end
  end
end

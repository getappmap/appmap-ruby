# frozen_string_literal: true

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

        class Call < AppMap::Trace::MethodEvent
          attr_accessor :payload

          def initialize(path, lineno, payload)
            super AppMap::Trace.next_id_counter, :call, HTTPServerRequest, :call, path, lineno, false, Thread.current.object_id

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
          event = Call.new(__FILE__, __LINE__, payload)
          Thread.current[context_key] = Context.new(event.id, Time.now)
          AppMap::Trace.tracers.record_event(event)
        end
      end

      class HTTPServerResponse
        include ContextKey

        class Call < AppMap::Trace::MethodReturnIgnoreValue
          attr_accessor :payload

          def initialize(path, lineno, payload, parent_id, elapsed)
            super AppMap::Trace.next_id_counter, :return, HTTPServerResponse, :call, path, lineno, false, Thread.current.object_id

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

          event = Call.new(__FILE__, __LINE__, payload, context.id, Time.now - context.start_time)
          AppMap::Trace.tracers.record_event(event)
        end
      end
    end
  end
end

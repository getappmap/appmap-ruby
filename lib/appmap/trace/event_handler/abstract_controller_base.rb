module AppMap
  module Trace
    module EventHandler
      module AbstractControllerBase
        class Call < MethodEvent
          attr_accessor :http_server_request, :message

          class << self
            def build_from_tracepoint(mc = Call.new, tp, path)
              mc.tap do |_|
                request = value_in_binding(tp, 'request')
                params = value_in_binding(tp, 'request.filtered_parameters')

                mc.http_server_request = {
                  request_method: request.request_method,
                  path_info: request.filtered_path,
                  protocol: request.protocol
                }
                mc.message = params

                MethodEvent.build_from_tracepoint(mc, tp, path)
              end
            end
          end

          def to_h
            super.tap do |h|
              h[:http_server_request] = http_server_request
              h[:message] = message.keys.reduce({}) do |memo, key|
                memo.tap do |_|
                  memo[key] = self.class.display_string(message[key])
                end
              end
            end
          end
        end

        class Return < MethodReturnIgnoreValue
          attr_accessor :http_server_response

          class << self
            def build_from_tracepoint(mr = Return.new, tp, path, parent_id, elapsed)
              mr.tap do |_|
                response = value_in_binding(tp, :response)

                mr.http_server_response = {
                  status: response.status
                }

                MethodReturnIgnoreValue.build_from_tracepoint(mr, tp, path, parent_id, elapsed)
              end
            end
          end

          def to_h
            super.tap do |h|
              h[:http_server_response] = http_server_response
            end
          end
        end
      end
    end
  end
end

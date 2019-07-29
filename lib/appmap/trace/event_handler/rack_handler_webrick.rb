module AppMap
  module Trace
    module EventHandler
      # Use the `req` and `res` parameters on Rack::Handler::WEBrick to populate the
      # `http_server_request` and `http_server_response` info on the trace event.
      #
      # See https://github.com/rack/rack/blob/b72bfc9435c118c54019efae1fedd119521b76df/lib/rack/handler/webrick.rb#L26
      module RackHandlerWebrick
        class Call < MethodEvent
          attr_accessor :http_server_request

          class << self
            def build_from_tracepoint(mc = Call.new, tp, path)
              mc.tap do |_|
                req = value_in_binding(tp, :req)

                # Don't try and grab 'parameters', because:
                # a) They aren't needed.
                # b) We want to avoid triggering side effects like reading the request body.

                mc.http_server_request = {
                  request_method: req.request_method,
                  path_info: req.path_info,
                  protocol: "HTTP/#{req.http_version}"
                }

                MethodEvent.build_from_tracepoint(mc, tp, path)
              end
            end
          end

          def to_h
            super.tap do |h|
              h[:http_server_request] = http_server_request
            end
          end
        end

        class Return < MethodReturnIgnoreValue
          attr_accessor :http_server_response

          class << self
            def build_from_tracepoint(mr = Return.new, tp, path, parent_id, elapsed)
              mr.tap do |_|
                res = value_in_binding(tp, :res)

                mr.http_server_response = {
                  status: res.status
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

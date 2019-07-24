module AppMap
  module Trace
    module EventHandler
      # Use the `req` and `res` parameters on Rack::Handler::WEBrick to populate the
      # `http_server_request` and `http_server_response` info on the trace event.
      #
      # See https://github.com/rack/rack/blob/b72bfc9435c118c54019efae1fedd119521b76df/lib/rack/handler/webrick.rb#L26
      module RackHandlerWebrick
        class Call < MethodEvent
          attr_accessor :http_request_method, :http_path_info, :http_version

          class << self
            def build_from_tracepoint(mc = Call.new, tp, path)
              mc.tap do |_|
                req = value_in_binding(tp, :req)

                # Don't try and grab 'self' and 'parameters', because:
                # a) They aren't needed.
                # b) We want to avoid triggering side effects like reading the request body.

                mc.http_request_method = req.request_method
                mc.http_path_info = req.path_info
                mc.http_version = "HTTP/#{req.http_version}"

                MethodEvent.build_from_tracepoint(mc, tp, path)
              end
            end
          end

          def to_h
            super.tap do |h|
              h[:http_server_request] = {
                request_method: http_request_method,
                path_info: http_path_info,
                version: http_version
              }
            end
          end
        end

        class Return < MethodEvent
          attr_accessor :parent_id, :elapsed, :http_status, :http_header

          class << self
            def build_from_tracepoint(mr = Return.new, tp, path, parent_id, elapsed)
              mr.tap do |_|
                res = value_in_binding(tp, :res)

                mr.parent_id = parent_id
                mr.elapsed = elapsed
                mr.http_status = res.status

                MethodEvent.build_from_tracepoint(mr, tp, path)
              end
            end
          end

          def to_h
            super.tap do |h|
              h[:parent_id] = parent_id
              h[:elapsed] = elapsed
              h[:http_server_response] = {
                status: http_status
              }
            end
          end
        end
      end
    end
  end
end

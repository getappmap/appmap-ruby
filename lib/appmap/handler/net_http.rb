# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Handler
    class HTTPClientRequest < AppMap::Event::MethodEvent
      attr_accessor :normalized_path_info, :request_method, :path_info, :params, :mime_type, :headers, :authorization

      def initialize(request)
        super AppMap::Event.next_id_counter, :call, Thread.current.object_id

        self.request_method = request.method
        self.path_info = request.path.split('?')[0]
        self.mime_type = request['Content-Type']
        self.headers = RequestHandler.selected_headers(request)
        self.authorization = request['Authorization']
        self.params = request.uri.params
      end

      def to_h
        super.tap do |h|
          h[:http_client_request] = {
            request_method: request_method,
            path_info: path_info,
            mime_type: mime_type,
            headers: headers,
            authorization: authorization,
          }.compact

          h[:message] = params.keys.map do |key|
            val = params[key]
            {
              name: key,
              class: val.class.name,
              value: self.class.display_string(val),
              object_id: val.__id__,
            }
          end
        end
      end
    end

    class HTTPClientResponse < AppMap::Event::MethodReturnIgnoreValue
      attr_accessor :status, :mime_type, :headers

      def initialize(response, parent_id, elapsed)
        super AppMap::Event.next_id_counter, :return, Thread.current.object_id

        self.status = response.code
        self.mime_type = response['Content-Type']
        self.parent_id = parent_id
        self.elapsed = elapsed
        self.headers = RequestHandler.selected_headers(response)
      end

      def to_h
        super.tap do |h|
          h[:http_client_response] = {
            status_code: status,
            mime_type: mime_type,
            headers: headers
          }.compact
        end
      end
    end

    class NetHTTP
      def handle_call(defined_class, hook_method, receiver, args)
        request = args.first
        HTTPClientRequest.new(request).tap do |call_event|
          AppMap.tracing.record_event call_event, package: hook_package, defined_class: defined_class, method: hook_method
        end
      end

      def handle_return(call_event_id, elapsed, return_value, exception)
        HTTPClientResponse.new(return_value, call_event.id, elapsed).tap do |return_event|
          AppMap.tracing.record_event return_event
        end
      end
    end
  end
end

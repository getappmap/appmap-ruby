# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Handler
    class HTTPClientRequest < AppMap::Event::MethodEvent
      attr_accessor :request_method, :url, :params, :headers

      def initialize(http, request)
        super AppMap::Event.next_id_counter, :call, Thread.current.object_id

        path, query = request.path.split('?')
        query ||= ''

        protocol = http.use_ssl? ? 'https' : 'http'
        port = if http.use_ssl? && http.port == 443
          nil
        elsif !http.use_ssl? && http.port == 80
          nil
        else
          ":#{http.port}"
        end

        url = [ protocol, '://', http.address, port, path ].compact.join

        self.request_method = request.method
        self.url = url
        self.headers = AppMap::Util.select_headers(NetHTTP.request_headers(request))
        self.params = Rack::Utils.parse_nested_query(query)
      end

      def to_h
        super.tap do |h|
          h[:http_client_request] = {
            request_method: request_method,
            url: url,
            headers: headers
          }.compact

          unless Util.blank?(params)
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
    end

    class HTTPClientResponse < AppMap::Event::MethodReturnIgnoreValue
      attr_accessor :status, :mime_type, :headers

      def initialize(response, parent_id, elapsed)
        super AppMap::Event.next_id_counter, :return, Thread.current.object_id

        self.status = response.code.to_i
        self.parent_id = parent_id
        self.elapsed = elapsed
        self.headers = AppMap::Util.select_headers(NetHTTP.response_headers(response))
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
      class << self
        def request_headers(request)
          {}.tap do |headers|
            request.each_header do |k,v|
              key = [ 'HTTP', k.underscore.upcase ].join('_')
              headers[key] = v
            end
          end
        end
    
        alias response_headers request_headers
    
        def handle_call(defined_class, hook_method, receiver, args)
          # request will call itself again in a start block if it's not already started.
          return unless receiver.started?

          http = receiver
          request = args.first
          HTTPClientRequest.new(http, request)
        end

        def handle_return(call_event_id, elapsed, return_value, exception)
          HTTPClientResponse.new(return_value, call_event_id, elapsed)
        end
      end
    end
  end
end

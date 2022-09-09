# frozen_string_literal: true

require 'appmap/event'
require 'appmap/hook/method'
require 'appmap/util'
require 'rack'

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
        self.headers = NetHTTPHandler.copy_headers(request)
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
      attr_accessor :status, :headers

      def initialize(response, parent_id, elapsed_before, elapsed, after_start_time)
        super AppMap::Event.next_id_counter, :return, Thread.current.object_id

        if response
          self.status = response.code.to_i
          self.headers = NetHTTPHandler.copy_headers(response)
        else
          self.headers = {}
        end
        self.parent_id = parent_id
        self.elapsed = elapsed
        self.elapsed_instrumentation = elapsed_before + (AppMap::Util.gettime() - after_start_time)
      end

      def to_h
        super.tap do |h|
          h[:http_client_response] = {
            status_code: status,
            headers: headers
          }.compact
        end
      end
    end

    # Handler class for HTTP requests.
    # Emits HTTP request events instead of method calls.
    class NetHTTPHandler < Hook::Method
      def self.copy_headers(obj)
        {}.tap do |headers|
          obj.each_header do |key, value|
            key = key.split('-').map(&:capitalize).join('-')
            headers[key] = value
          end
        end
      end

      def handle_call(receiver, args)
        # request will call itself again in a start block if it's not already started.
        return unless receiver.started?

        http = receiver
        request = args.first
        HTTPClientRequest.new(http, request)
      end

      def handle_return(call_event_id, elapsed_before, elapsed, after_start_time, return_value, exception)
        HTTPClientResponse.new(return_value, call_event_id, elapsed_before, elapsed, after_start_time)
      end
    end
  end
end

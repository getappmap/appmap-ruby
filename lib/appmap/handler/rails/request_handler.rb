# frozen_string_literal: true

require 'appmap/event'
require 'appmap/hook'
require 'appmap/util'

module AppMap
  module Handler
    module Rails

      module RequestHandler
        class HTTPServerRequest < AppMap::Event::MethodEvent
          attr_accessor :normalized_path_info, :request_method, :path_info, :params, :headers

          def initialize(request)
            super AppMap::Event.next_id_counter, :call, Thread.current.object_id

            self.request_method = request.request_method
            self.normalized_path_info = AppMap::Util.route_from_request(request)
            self.headers = AppMap::Util.select_rack_headers(request.env)
            self.path_info = request.path_info.split('?')[0]
            # ActionDispatch::Http::ParameterFilter is deprecated
            parameter_filter_cls = \
              if defined?(ActiveSupport::ParameterFilter)
                ActiveSupport::ParameterFilter
              else
                ActionDispatch::Http::ParameterFilter
              end
            self.params = parameter_filter_cls.new(::Rails.application.config.filter_parameters).filter(request.params)
          end

          def to_h
            super.tap do |h|
              h[:http_server_request] = {
                request_method: request_method,
                path_info: path_info,
                normalized_path_info: normalized_path_info,
                headers: headers,
              }.compact

              unless Util.blank?(params)
                h[:message] = params.keys.map do |key|
                  val = params[key]
                  {
                    name: key,
                    class: val.class.name,
                    value: self.class.display_string(val),
                    object_id: val.__id__,
                  }.tap do |message|
                    AppMap::Event::MethodEvent.add_schema message, val
                  end
                end
              end
            end
          end
        end

        class HTTPServerResponse < AppMap::Event::MethodReturn
          attr_accessor :status, :headers

          class << self
            def build_from_invocation(parent_id, return_value, elapsed, response, event: HTTPServerResponse.new)
              event ||= HTTPServerResponse.new
              event.status = response.status
              event.headers = response.headers.dup
              AppMap::Event::MethodReturn.build_from_invocation parent_id, return_value, nil, elapsed: elapsed, event: event, parameter_schema: true
            end
          end

          def to_h
            super.tap do |h|
              h[:http_server_response] = {
                status_code: status,
                headers: headers
              }.compact
            end
          end
        end

        class HookMethod < AppMap::Hook::Method
          def initialize
            # ActionController::Instrumentation has issued start_processing.action_controller and
            # process_action.action_controller since Rails 3. Therefore it's a stable place to hook
            # the request. Rails controller notifications can't be used directly because they don't
            # provide response headers, and we want the Content-Type.
            super(nil, ActionController::Instrumentation, ActionController::Instrumentation.instance_method(:process_action))
          end

          protected

          def before_hook(receiver, *)
            call_event = HTTPServerRequest.new(receiver.request)
            # http_server_request events are i/o and do not require a package name.
            AppMap.tracing.record_event call_event, defined_class: defined_class, method: hook_method
            call_event
          end

          def after_hook(receiver, call_event, elapsed, *)
            return_value = Thread.current[TEMPLATE_RENDER_VALUE]
            Thread.current[TEMPLATE_RENDER_VALUE] = nil
            return_event = HTTPServerResponse.build_from_invocation call_event.id, return_value, elapsed, receiver.response
            AppMap.tracing.record_event return_event
          end
        end
      end
    end
  end
end

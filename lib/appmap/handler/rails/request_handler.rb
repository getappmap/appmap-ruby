# frozen_string_literal: true

require 'appmap/event'
require 'appmap/hook'
require 'appmap/util'

module AppMap
  module Handler
    module Rails

      module RequestHandler
        class HTTPServerRequest < AppMap::Event::MethodEvent
          attr_accessor :normalized_path_info, :request_method, :path_info, :params, :headers, :call_elapsed_instrumentation

          def initialize(request)
            super AppMap::Event.next_id_counter, :call, Thread.current.object_id

            self.request_method = request.request_method
            self.normalized_path_info = normalized_path(request)
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

          private

          def normalized_path(request, router = ::Rails.application.routes.router)
            router.recognize request do |route, _|
              app = route.app
              next unless app.matches? request
              return normalized_path request, app.rack_app.routes.router if app.engine?

              return AppMap::Util.swaggerize_path(route.path.spec.to_s)
            end
          end
        end

        class HTTPServerResponse < AppMap::Event::MethodReturn
          attr_accessor :status, :headers

          class << self
            def build_from_invocation(parent_id, return_value, elapsed, response, event: HTTPServerResponse.new)
              event ||= HTTPServerResponse.new
              event.status = response[:status] || response.status
              event.headers = (response[:headers] || response.headers).dup
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
            before_hook_start_time = AppMap::Util.gettime()
            call_event = HTTPServerRequest.new(receiver.request)
            call_event.call_elapsed_instrumentation = (AppMap::Util.gettime() - before_hook_start_time)
            # http_server_request events are i/o and do not require a package name.
            AppMap.tracing.record_event call_event, defined_class: defined_class, method: hook_method
            call_event
          end

          def after_hook(receiver, call_event, elapsed, *)
            after_hook_start_time = AppMap::Util.gettime()
            return_value = Thread.current[TEMPLATE_RENDER_VALUE]
            Thread.current[TEMPLATE_RENDER_VALUE] = nil
            return_event = HTTPServerResponse.build_from_invocation call_event.id, return_value, elapsed, receiver.response
            return_event.elapsed_instrumentation = (AppMap::Util.gettime() - after_hook_start_time) + call_event.call_elapsed_instrumentation
            call_event.call_elapsed_instrumentation = nil # to stay consistent with elapsed_instrumentation only being stored in return
            AppMap.tracing.record_event return_event
          end
        end

        # RequestListener listens to the 'start_processing.action_controller' notification as a
        # source of HTTP server request events. A strategy other than HookMethod is required for
        # Rails >= 7 due to the hooked methods visibility dropping to private.
        class RequestListener
          def self.begin_request(_name, _started, _finished, _unique_id, payload)
            RequestListener.new(payload)
          end

          protected

          def initialize(payload)
            @request_id = payload[:request].request_id
            @subscriber = self.class.instance_method(:after_hook).bind(self)

            ActiveSupport::Notifications.subscribe 'process_action.action_controller', @subscriber
            before_hook payload
          end

          def before_hook(payload)
            before_hook_start_time = AppMap::Util.gettime()
            @call_event = HTTPServerRequest.new payload[:request]
            @call_event.call_elapsed_instrumentation = (AppMap::Util.gettime() - before_hook_start_time)
            AppMap.tracing.record_event @call_event
          end

          def after_hook(_name, started, finished, _unique_id, payload)
            return unless @request_id == payload[:request].request_id

            after_hook_start_time = AppMap::Util.gettime()
            return_value = Thread.current[TEMPLATE_RENDER_VALUE]
            Thread.current[TEMPLATE_RENDER_VALUE] = nil
            return_event = HTTPServerResponse.build_from_invocation(
              @call_event.id,
              return_value,
              finished - started,
              payload[:response] || payload
            )
            return_event.elapsed_instrumentation = (AppMap::Util.gettime() - after_hook_start_time) + @call_event.call_elapsed_instrumentation

            AppMap.tracing.record_event return_event
            ActiveSupport::Notifications.unsubscribe(@subscriber)
          end
        end
      end
    end
  end
end

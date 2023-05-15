# frozen_string_literal: true

require 'appmap/event'
require 'appmap/hook'
require 'appmap/util'
require 'appmap/handler/rails/context'

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
            # use a cloned environment because the router can modify it
            request = ActionDispatch::Request.new request.env.clone
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
            req = receiver.request
            return unless Context.create req.env

            before_hook_start_time = AppMap::Util.gettime()
            call_event = HTTPServerRequest.new(req)
            call_event.call_elapsed_instrumentation = (AppMap::Util.gettime() - before_hook_start_time)
            # http_server_request events are i/o and do not require a package name.
            AppMap.tracing.record_event call_event, defined_class: defined_class, method: hook_method
            call_event
          end

          def after_hook(receiver, call_event, elapsed, *)
            after_hook_start_time = AppMap::Util.gettime()
            return_event = HTTPServerResponse.build_from_invocation \
              call_event.id, Context.new.find_template_render_value, elapsed, receiver.response
            return_event.elapsed_instrumentation = (AppMap::Util.gettime() - after_hook_start_time) + call_event.call_elapsed_instrumentation
            call_event.call_elapsed_instrumentation = nil # to stay consistent with elapsed_instrumentation only being stored in return
            AppMap.tracing.record_event return_event
            Context.remove receiver.request.env
          end
        end

        # Additional hook for the Rack stack in Rails applications.
        #
        # Hooking just in ActionController can be inaccurate if there's a middleware that
        # intercepts the response and modifies it, or catches an exception
        # or an object and does some other processing.
        # For example, Devise catches a throw from warden on authentication error, then runs
        # ActionController stack AGAIN to render a login page, which it then modifies to change
        # the HTTP status code.
        # ActionDispatch::Executor seems a good place to hook as the central entry point
        # in a Rails application; there are a couple middleware that sometimes sit on top of it
        # but they're usually inconsequential. One issue is that the executor can be entered several
        # times in the stack (especially if Rails engines are used). To handle that, we set
        # a context in the request environment the first time we enter it.
        class RackHook < AppMap::Hook::Method
          def initialize
            super(nil, ActionDispatch::Executor, ActionDispatch::Executor.instance_method(:call))
          end

          protected

          def before_hook(_receiver, env)
            return unless Context.create env

            before_hook_start_time = AppMap::Util.gettime
            call_event = HTTPServerRequest.new ActionDispatch::Request.new(env)
            # http_server_request events are i/o and do not require a package name.
            AppMap.tracing.record_event call_event, defined_class: defined_class, method: hook_method
            [call_event, (AppMap::Util.gettime - before_hook_start_time)]
          end

          # NOTE: this method smells of :reek:LongParameterList and :reek:UtilityFunction
          # because of the interface it implements.
          # rubocop:disable Metrics/ParameterLists
          def after_hook(_receiver, call_event, elapsed_before, elapsed, after_hook_start_time, rack_return, _exception)
            # TODO: handle exceptions
            return_event = HTTPServerResponse.build_from_invocation \
              call_event.id, Context.new.find_template_render_value, elapsed, ActionDispatch::Response.new(*rack_return)
            return_event.elapsed_instrumentation = (AppMap::Util.gettime - after_hook_start_time) + elapsed_before
            AppMap.tracing.record_event return_event
          end
          # rubocop:enable Metrics/ParameterLists
        end

        # RequestListener listens to the 'start_processing.action_controller' notification as a
        # source of HTTP server request events. A strategy other than HookMethod is required for
        # Rails >= 7 due to the hooked methods visibility dropping to private.
        class RequestListener
          def self.begin_request(_name, _started, _finished, _unique_id, payload)
            return unless Context.create payload[:request].env

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
            return_event = HTTPServerResponse.build_from_invocation(
              @call_event.id,
              Context.new.find_template_render_value,
              finished - started,
              payload[:response] || payload
            )
            return_event.elapsed_instrumentation = (AppMap::Util.gettime() - after_hook_start_time) + @call_event.call_elapsed_instrumentation

            AppMap.tracing.record_event return_event
            Context.remove payload[:request].env
            ActiveSupport::Notifications.unsubscribe(@subscriber)
          end
        end
      end
    end
  end
end

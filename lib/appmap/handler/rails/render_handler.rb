require 'appmap/handler/function_handler'

module AppMap
  module Handler
    module Rails
      class RenderHandler < AppMap::Handler::FunctionHandler
        def handle_call(receiver, args)
          options, _ = args
          # TODO: :file, :xml
          # https://guides.rubyonrails.org/v5.1/layouts_and_rendering.html
          if options[:json]
            Thread.current[TEMPLATE_RENDER_FORMAT] = :json
          end

          super
        end

        def handle_return(call_event_id, elapsed, return_value, exception)
          if Thread.current[TEMPLATE_RENDER_FORMAT] == :json
            Thread.current[TEMPLATE_RENDER_VALUE] = JSON.parse(return_value) rescue nil
          end
          Thread.current[TEMPLATE_RENDER_FORMAT] = nil

          super
        end
      end
    end
  end
end

require 'appmap/handler/function'

module AppMap
  module Handler
    module Rails
      class RenderHandler < AppMap::Handler::Function
        def handle_call(receiver, args)
          options, _ = args
          if options[:json]
            Thread.current[TEMPLATE_RENDER_VALUE] = options[:json]
          end

          super
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'appmap/handler/function_handler'

module AppMap
  module Handler
    class MarshalLoadHandler < FunctionHandler
      PARAMETERS= [
        [ :req, :source ],
        [ :rest ],
      ]

      def handle_call(receiver, args)
        AppMap::Event::MethodCall.build_from_invocation(defined_class, hook_method, receiver, args, parameters: PARAMETERS)
      end
    end
  end
end

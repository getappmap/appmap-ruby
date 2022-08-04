require 'appmap/handler/function_handler'

module AppMap
  module Handler
    class OpenSSLHandler < FunctionHandler
      def handle_call(receiver, args)
        super.tap do |event|
          algorithm = receiver.name
          event.receiver[:labels] ||= []
          label = [ 'crypto.algorithm', algorithm ].join('.')
          event.receiver[:labels] << label unless event.receiver[:labels].include?(label)
        end
      end
    end
  end
end

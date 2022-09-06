require 'appmap/handler/function_handler'

module AppMap
  module Handler
    class AssociationHandler < FunctionHandler
      ASSOCIATION_PROPERTIES = %i[name table_name class_name].freeze
      @@warn_on_receiver_type = Set.new

      def handle_call(receiver, args)
        super.tap do |event|
          reflection = \
            if receiver.respond_to?(:reflection)
              receiver.reflection
            elsif receiver.instance_variables.member?(:@association)
              receiver.instance_variable_get("@association").reflection
            end

          unless reflection
            unless @@warn_on_receiver_type.member?(receiver.class)
              warn "AppMap: Association details are not available for #{receiver.class}"
              @@warn_on_receiver_type << receiver.class
            end
            return
          end

          properties = \
            ASSOCIATION_PROPERTIES
              .each_with_object([]) do |m, memo|
                value = reflection.send(m) rescue nil
                memo << {
                  name: m.to_s,
                  class: String,
                  value: value.to_s
                } if [ String, Symbol ].find {|t| value.is_a?(t)}
              end
          event.receiver[:properties] = properties
        end
      end
    end
  end
end

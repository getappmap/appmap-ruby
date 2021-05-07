# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Handler
    module Rails
      TemplateMethod = Struct.new(:path, :name) do
        private_methods :path

        def package
          'views'
        end

        def class_name
          'ViewTemplate'
        end

        def source_location
          path
        end

        def static
          true
        end

        def comment
          nil
        end

        def labels
          []
        end
      end

      module TemplateEvent
        def self.included(base)
          attr_accessor :lookup_context, :render_template
        end

        def to_h
          super.tap do |h|
            h[:render_template] = render_template if render_template
          end
        end
      end

      class TemplateHandler
        def initialize(template_type)
          @template_type = template_type
        end

        class << self
          def handle_call(defined_class, hook_method, receiver, args)
            AppMap::Handler::Function.handle_call(defined_class, hook_method, receiver, args).tap do |event|
              class << event
                include TemplateEvent
              end
              event.lookup_context = receiver.lookup_context
            end
          end

          def handle_return(call_event_id, elapsed, return_value, exception)
            AppMap::Handler::Function.handle_return(call_event_id, elapsed, return_value, exception)
          end
        end

        def call(_, started, finished, _, payload) # (name, started, finished, unique_id, payload)
          return if AppMap.tracing.empty?

          path = payload[:identifier]
          layout = payload[:layout]

          return warn "No :identifier in template payload #{payload.inspect}" unless path

          return unless File.exists?(path)

          view_event = AppMap.tracing.find_last_event do |event|
            event.is_a?(TemplateEvent)
          end
          return warn "TemplateEvent not found for #{payload.inspect}" unless view_event

          trim_path = ->(path) { path.index(Dir.pwd) == 0 ? path[Dir.pwd.length + 1..-1] : path }

          path = trim_path.(path)

          if layout
            layout_path = view_event.lookup_context.find_template(layout)
            layout_path = trim_path.(layout_path.inspect)
          end

          render_template = {
            path: path,
            layout_path: layout_path,
            template_type: @template_type
          }.compact

          AppMap.tracing.record_method(TemplateMethod.new(path, :render))
          AppMap.tracing.record_method(TemplateMethod.new(layout_path, :render_template))

          view_event.render_template = render_template
        end
      end
    end
  end
end

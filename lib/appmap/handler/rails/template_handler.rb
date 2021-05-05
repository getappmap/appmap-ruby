# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Handler
    module Rails
      TemplateMethod = Struct.new(:path) do
        private_methods :path

        def package
          'views'
        end

        def class_name
          'ViewTemplate'
        end

        def name
          'render'
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
          attr_accessor :render_template
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
            end
          end

          def handle_return(call_event_id, elapsed, return_value, exception)
            AppMap::Handler::Function.handle_return(call_event_id, elapsed, return_value, exception)
          end
        end

        def call(_, started, finished, _, payload) # (name, started, finished, unique_id, payload)
          return if AppMap.tracing.empty?

          path = payload[:identifier]
          unless path
            warn "No :identifier in template payload #{payload.inspect}"
            return
          end

          path = path[Dir.pwd.length + 1..-1] if path.index(Dir.pwd) == 0
          layout = payload[:layout]

          render_template = {
            path: path,
            template_type: @template_type,
            layout_path: layout
          }.compact

          AppMap.tracing.record_method(TemplateMethod.new(path))
          view_event = AppMap.tracing.find_last_event do |event|
            event.is_a?(TemplateEvent)
          end
          if view_event
            view_event.render_template = render_template
          else
            warn "TemplateEvent not found for #{payload.inspect}"
          end
        end
      end
    end
  end
end

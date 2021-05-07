# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Handler
    module Rails
      class TemplateCall < MethodEvent
        attr_reader :render_instance, :path

        def initialize(id, render_instance, path)
          super id, :call, Thread.current.object_id

          @render_instance = render_instance
          @path = path
        end
  
        def to_h
          super.tap do |h|
            # This is a lie. The class is really something like Template::HTML, but we don't have
            # access to that without doing more work.
            h[:defined_class] = render_instance.class.name
            h[:method_id] = [ 'render(', path, ')' ].join
            h[:path] = path
            h[:static] = true
            h[:parameters] = []
            h[:receiver] = {
              class: best_class_name(render_instance),
              object_id: render_instance.__id__,
              value: display_string(render_instance)
            }
            h.delete_if { |_, v| v.nil? }
          end
        end
  
        alias static? static
      end
  
      module TemplateEvent
        def self.included(base)
          attr_accessor :render_instance
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
              # Insert a gap into the event ids, so that when the template notification arrives, there is room
              # in the event list to inject up to two new :call events - one for the layout, and one for the template.
              AppMap::Event.next_id_counter += 2
              event.render_instance = receiver
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

          report_layout_event = lambda do
            layout_path = view_event.render_instance.lookup_context.find_template(layout)
            layout_path = trim_path.(layout_path.inspect)

            layout_event = TemplateCall.new(view_event.id + 1, view_event.render_instance, layout_path)

            AppMap.tracing.record_event(layout_event)
            AppMap.tracing.record_method(TemplateMethod.new(layout_path, %Q[layout(#{layout_path})]))
          end

          report_template_event = lambda do
            template_path = trim_path.(path)
  
            template_event = TemplateCall.new(view_event.id + 2, view_event.render_instance, template_path)
            AppMap.tracing.record_event(template_event)
            AppMap.tracing.record_method(TemplateMethod.new(layout_path, %Q[template(#{template_path})]))
          end

          report_layout_event.() if layout
          report_template_event.()
        end
      end
    end
  end
end

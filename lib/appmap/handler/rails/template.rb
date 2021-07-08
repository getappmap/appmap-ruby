# frozen_string_literal: true

require 'appmap/event'

module AppMap
  module Handler
    module Rails
      class Template
        LOG = (ENV['APPMAP_TEMPLATE_DEBUG'] == 'true' || ENV['DEBUG'] == 'true')

        # All the code which is touched by the AppMap is recorded in the classMap.
        # This duck-typed 'method' is used to represent a view template as a package, 
        # class, and method in the classMap.
        # The class name is generated from the template path. The package name is
        # 'app/views', and the method name is 'render'. The source location of the method
        # is, of course, the path to the view template.
        class TemplateMethod
          attr_reader :class_name

          attr_reader :path
          private_instance_methods :path

          def initialize(path)
            @path = path

            @class_name = path.parameterize.underscore
          end

          def id
            [ package, path, name ]
          end

          def hash
            id.hash
          end

          def eql?(other)
            other.is_a?(TemplateMethod) && id.eql?(other.id)
          end

          def package
            'app/views'
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
            [ 'mvc.template' ]
          end
        end
  
        # TemplateCall is a type of function call which is specialized to view template rendering. Since
        # there isn't really a perfect method in Rails to hook, this one is synthesized from the available
        # information. 
        class TemplateCall < AppMap::Event::MethodEvent
          # This is basically the +self+ parameter.
          attr_reader :render_instance
          # Path to the view template.
          attr_accessor :path
          # Indicates when the event is fully constructed.
          attr_accessor :ready

          alias ready? ready
 
          def initialize(render_instance)
            super :call
  
            AppMap::Event::MethodEvent.build_from_invocation(:call, event: self)
            @ready = false
            @render_instance = render_instance
          end
  
          def static?
            true
          end
    
          def to_h
            super.tap do |h|
              h[:defined_class] = path ? path.parameterize.underscore : 'inline_template'
              h[:method_id] = 'render'
              h[:path] = path
              h[:static] = static?
              h[:parameters] = []
              h[:receiver] = {
                class: AppMap::Event::MethodEvent.best_class_name(render_instance),
                object_id: render_instance.__id__,
                value: AppMap::Event::MethodEvent.display_string(render_instance)
              }
            end.compact
          end
        end
 
        TEMPLATE_RENDERER = 'appmap.handler.rails.template.renderer'

        # Hooks the ActionView::Resolver methods +find_all+, +find_all_anywhere+. The resolver is used
        # during template rendering to lookup the template file path from parameters such as the
        # template name, prefix, and partial (boolean).
        class ResolverHandler
          class << self
            # Handled as a normal function call.
            def handle_call(defined_class, hook_method, receiver, args)
              name, prefix, partial = args
              warn "Resolver: #{{ name: name, prefix: prefix, partial: partial }}" if LOG

              AppMap::Handler::Function.handle_call(defined_class, hook_method, receiver, args)
            end

            # When the resolver returns, look to see if there is template rendering underway.
            # If so, populate the template path. In all cases, add a TemplateMethod so that the
            # template will be recorded in the classMap.
            def handle_return(call_event_id, elapsed, return_value, exception)
              renderer = Array(Thread.current[TEMPLATE_RENDERER]).last
              path_obj = Array(return_value).first
              
              warn "Resolver return: #{path_obj}" if LOG

              if path_obj
                path = if path_obj.respond_to?(:identifier) && path_obj.inspect.index('#<')
                  path_obj.identifier
                else
                  path_obj.inspect
                end
                path = path[Dir.pwd.length + 1..-1] if path.index(Dir.pwd) == 0
                AppMap.tracing.record_method(TemplateMethod.new(path))
                renderer.path ||= path if renderer
              end

              AppMap::Handler::Function.handle_return(call_event_id, elapsed, return_value, exception)
            end
          end
        end

        # Hooks the ActionView::Renderer method +render+. This method is used by Rails to perform
        # template rendering. The TemplateCall event which is emitted by this handler has a
        # +path+ parameter, which is nil until it's filled in by a ResolverHandler. 
        class RenderHandler
          class << self
            def handle_call(defined_class, hook_method, receiver, args)
              # context, options
              _, options = args

              warn "Renderer: #{options}" if LOG

              TemplateCall.new(receiver).tap do |call|
                Thread.current[TEMPLATE_RENDERER] ||= []
                Thread.current[TEMPLATE_RENDERER] << call
              end
            end
  
            def handle_return(call_event_id, elapsed, return_value, exception)
              template_call = Array(Thread.current[TEMPLATE_RENDERER]).pop
              template_call.ready = true

              AppMap::Event::MethodReturnIgnoreValue.build_from_invocation(call_event_id, elapsed: elapsed)
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

require 'appmap/handler'

module AppMap
  module Handler
    module Rails
      # Context of a rails request tracking.
      # Mostly a utility class to clean up and deduplicate request handler code.
      class Context
        def initialize(environment = nil)
          environment[REQUEST_CONTEXT] = self if environment
          @thread = Thread.current
        end

        def self.from(environment)
          environment[REQUEST_CONTEXT]
        end

        def self.create(environment)
          return if from environment

          new environment
        end

        def self.remove(env)
          env[REQUEST_CONTEXT] = nil
        end

        def find_template_render_value
          @thread[TEMPLATE_RENDER_VALUE].tap do
            @thread[TEMPLATE_RENDER_VALUE] = nil
          end
        end

        # context is set on the rack environment to make sure a single request is only recorded once
        # even if ActionDispatch::Executor is entered more than once (as can happen with engines)
        REQUEST_CONTEXT = 'appmap.handler.request.context'
      end
    end
  end
end

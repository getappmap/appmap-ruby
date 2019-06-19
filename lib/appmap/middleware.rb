module AppMap
  # Middleware is a Rack app for recording a web request as a scenario.
  class Middleware
    CallStruct = Struct.new(:env, :trace_point, :events, :event_thread)

    # Call wraps a request with an AppMap tracer and dumps the result when the request
    # is completed.
    class Call < CallStruct
      def call
        begin_trace
        begin
          app.call(env)
        ensure
          end_trace
        end
      end

      def begin_trace
        inspect if inspect_required?
        setup_tracer
      end

      def inspect_required?
        @features.nil?
      end

      def inspect
        require 'appmap/config'
        require 'appmap/inspect'

        config = AppMap::Config.load_from_file(File.join(Rails.root, '.appmap.yml'))
        self.features = config.source_locations.map(&AppMap::Inspect.method(:detect_features))
      end

      def setup_tracer
        methods = features.map(&:collect_features).flatten

        require 'appmap/trace/tracer'

        tracer = AppMap::Trace.tracer = AppMap::Trace::Tracer.new(methods)
        self.trace_point = AppMap::Trace::Tracer.trace tracer

        self.events = []
        self.event_thread = Thread.new do
          while trace_point.enabled? || tracer.event?
            event = tracer.next_event
            if event
              events << event.to_h
            else
              sleep 0.0001
            end
          end
        end
        event_thread.abort_on_exception = true
      end

      def end_trace
        trace_point.disable
        event_thread.join

        File.write('appmap.json', JSON.generate(classMap: features, events: events))
      end
    end

    def initialize(app)
      @app = app
    end

    def call(env)
      require 'pry'; binding.pry
      return @app.call(env) unless enabled?

      Call.new(env).call
    end

    def enabled?
      File.exist?(File.join(Rails.root, 'tmp', 'appmap_enabled'))
    end
  end
end

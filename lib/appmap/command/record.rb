module AppMap
  module Command
    RecordStruct = Struct.new(:config, :program)

    class Record < RecordStruct
      def perform(&block)
        features = AppMap.inspect(config)
        functions = features.map(&:collect_functions).flatten

        require 'appmap/trace/tracer'

        tracer = AppMap::Trace.tracer = AppMap::Trace::Tracer.new(functions)
        AppMap::Trace::Tracer.trace tracer

        events = []
        quit = false
        event_thread = Thread.new do
          while tracer.event? || !quit
            event = tracer.next_event
            if event
              events << event.to_h
            else
              sleep 0.0001
            end
          end
        end
        event_thread.abort_on_exception = true

        at_exit do
          quit = true
          event_thread.join
          yield features, events
        end

        load program if program
      end
    end
  end
end

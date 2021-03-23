# frozen_string_literal: true

module AppMap
  module Command
    RecordStruct = Struct.new(:config, :program)

    class Record < RecordStruct
      def perform(&block)
        tracer = AppMap.tracing.trace

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
          yield AppMap::APPMAP_FORMAT_VERSION,
                AppMap.detect_metadata,
                AppMap.class_map(tracer.event_methods, include_source: AppMap.include_source?),
                events
        end

        load program if program
      end
    end
  end
end

module AppMap
  class Hook
    # Start and stop a recording around a Hook::Method.
    module RecordAround
      APPMAP_OUTPUT_DIR = File.join(AppMap.output_dir, "requests")

      # Context for a recording.
      class Context
        attr_reader :hook_method

        def initialize(hook_method)
          @hook_method = hook_method
          @start_time = DateTime.now
          @tracer = AppMap.tracing.trace(thread: Thread.current)
        end

        # Finish recording the AppMap by collecting the events and classMap and writing the output file.
        # rubocop:disable Metrics/MethodLength
        # rubocop:disable Metrics/AbcSize
        def finish
          return unless @tracer

          tracer = @tracer
          @tracer = nil
          AppMap.tracing.delete(tracer)

          events = tracer.events.map(&:to_h)

          timestamp = DateTime.now
          appmap_name = "#{hook_method.name} (#{Thread.current.object_id}) - #{timestamp.strftime("%T.%L")}"
          appmap_file_name = AppMap::Util.scenario_filename([timestamp.to_f, hook_method.name, Thread.current.object_id].join("_"))

          metadata = AppMap.detect_metadata.tap do |metadata|
            metadata[:name] = appmap_name
            metadata[:source_location] = hook_method.source_location
            metadata[:recorder] = {
              name: "command",
              type: "requests"
            }
          end

          appmap = {
            version: AppMap::APPMAP_FORMAT_VERSION,
            classMap: AppMap.class_map(tracer.event_methods),
            metadata: metadata,
            events: events
          }

          AppMap::Util.write_appmap(File.join(APPMAP_OUTPUT_DIR, appmap_file_name), appmap)
        end
        # rubocop:enable Metrics/MethodLength
        # rubocop:enable Metrics/AbcSize
      end

      # If requests recording is enabled, and we encounter a method which should always be recorded
      # when requests recording is on, and there is no other recording in progress, then start a
      # new recording and end it when the method returns.
      def record_around?
        (record_around && AppMap.recording_enabled?(:requests) && !AppMap.tracing_enabled?(thread: Thread.current))
      end

      def record_around_before
        return unless record_around?

        @record_around_context = Context.new(hook_method)
      end

      def record_around_after
        return unless @record_around_context

        context = @record_around_context
        @record_around_context = nil
        context.finish
      end
    end
  end
end

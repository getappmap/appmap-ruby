# frozen_string_literal: true

module AppMap
  module Middleware
    # RemoteRecording adds `/_appmap/record` routes to control recordings via HTTP requests.
    # It can also be enabled to emit an AppMap for each request.
    class RemoteRecording
      def initialize(app)
        require 'json'

        @app = app
      end

      def event_loop
        loop do
          event = @tracer.next_event if @tracer
          if event
            @events << event.to_h
          else
            sleep 0.0001
          end
        end
      end

      def ws_start_recording
        return [ 409, 'Recording is already in progress' ] if @tracer

        @events = []
        @tracer = AppMap.tracing.trace
        @event_thread = Thread.new { event_loop }
        @event_thread.abort_on_exception = true

        [ 200 ]
      end

      def ws_stop_recording(req)
        return [ 404, 'No recording is in progress' ] unless @tracer

        tracer = @tracer
        @tracer = nil

        AppMap.tracing.delete(tracer)

        @event_thread.exit
        @event_thread.join
        @event_thread = nil

        # Delete the events which are calls to or returns from the URL path _appmap/record
        # because these are not of interest to the user.
        is_control_command_event = lambda do |event|
          event[:event] == :call &&
            event[:http_server_request] &&
            event[:http_server_request][:path_info] == '/_appmap/record'
        end
        control_command_events = @events.select(&is_control_command_event)

        is_return_from_control_command_event = lambda do |event|
          event[:parent_id] && control_command_events.find { |e| e[:id] == event[:parent_id] }
        end

        @events.delete_if(&is_control_command_event)
        @events.delete_if(&is_return_from_control_command_event)

        metadata = AppMap.detect_metadata
        metadata[:recorder] = {
          name: 'remote_recording',
          type: 'remote'
        }

        response = JSON.generate \
          version: AppMap::APPMAP_FORMAT_VERSION,
          classMap: AppMap.class_map(tracer.event_methods),
          metadata: metadata,
          events: @events

        [ 200, response ]
      end

      def call(env)
        # Note: Puma config is avaliable here. For example:
        # $ env['puma.config'].final_options[:workers]
        # 0

        req = Rack::Request.new(env)
        return handle_record_request(req) if AppMap.recording_enabled?(:remote) && req.path == '/_appmap/record'

        start_time = Time.now
        # Support multi-threaded web server such as Puma by recording each thread
        # into a separate Tracer.
        tracer = AppMap.tracing.trace(thread: Thread.current) if record_all_requests?

        record_request = lambda do |args|
          return unless tracer

          AppMap.tracing.delete(tracer)

          status, headers = args
          events = tracer.events.map(&:to_h)

          event_fields = events.map(&:keys).flatten.map(&:to_sym).uniq.sort
          return unless %i[http_server_request http_server_response].all? { |field| event_fields.include?(field) }

          path = req.path.gsub(/\/{2,}/, '/') # Double slashes have been observed
          appmap_name = "#{req.request_method} #{path} (#{status}) - #{start_time.strftime('%T.%L')}"
          appmap_file_name = AppMap::Util.scenario_filename([ start_time.to_f, req.url ].join('_'))
          output_dir = File.join(AppMap::DEFAULT_APPMAP_DIR, 'requests')
          appmap_file_path = File.join(output_dir, appmap_file_name)

          metadata = AppMap.detect_metadata
          metadata[:name] = appmap_name
          metadata[:timestamp] = start_time.to_f
          metadata[:recorder] = {
            name: 'rack',
            type: 'requests'
          }
  
          appmap = {
            version: AppMap::APPMAP_FORMAT_VERSION,
            classMap: AppMap.class_map(tracer.event_methods),
            metadata: metadata,
            events: events
          }

          FileUtils.mkdir_p(output_dir)
          File.write(appmap_file_path, JSON.generate(appmap))

          headers['AppMap-Name'] = File.expand_path(appmap_name)
          headers['AppMap-File-Name'] = File.expand_path(appmap_file_path)
        end

        @app.call(env).tap(&record_request)
      end

      def recording_state
        [ 200, JSON.generate({ enabled: recording? }) ]
      end

      def handle_record_request(req)
        method = req.env['REQUEST_METHOD']

        status, body = \
          if method.eql?('GET')
            recording_state
          elsif method.eql?('POST')
            ws_start_recording
          elsif method.eql?('DELETE')
            ws_stop_recording(req)
          else
            [ 404, '' ]
          end

        [status, { 'Content-Type' => 'application/json' }, [body || '']]
      end

      def html_response?(headers)
        headers['Content-Type'] && headers['Content-Type'] =~ /html/
      end

      def record_all_requests?
        AppMap.recording_enabled?(:requests)
      end

      def recording?
        !@event_thread.nil?
      end
    end
  end
end

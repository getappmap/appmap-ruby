# frozen_string_literal: true

module AppMap
  module Middleware
    # RemoteRecording adds `/_appmap/record` routes to control recordings via HTTP requests
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

      def start_recording
        return [ 409, 'Recording is already in progress' ] if @tracer

        @events = []
        @tracer = AppMap.tracing.trace
        @event_thread = Thread.new { event_loop }
        @event_thread.abort_on_exception = true

        [ 200 ]
      end

      def stop_recording(req)
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
          name: 'remote_recording'
        }

        response = JSON.generate \
          version: AppMap::APPMAP_FORMAT_VERSION,
          classMap: AppMap.class_map(tracer.event_methods),
          metadata: metadata,
          events: @events

        [ 200, response ]
      end

      def call(env)
        req = Rack::Request.new(env)
        return handle_record_request(req) if req.path == '/_appmap/record'

        @app.call(env)
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
            start_recording
          elsif method.eql?('DELETE')
            stop_recording(req)
          else
            [ 404, '' ]
          end

        [status, { 'Content-Type' => 'application/json' }, [body || '']]
      end

      def html_response?(headers)
        headers['Content-Type'] && headers['Content-Type'] =~ /html/
      end

      def recording?
        !@event_thread.nil?
      end
    end
  end
end

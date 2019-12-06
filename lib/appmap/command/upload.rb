require 'json'
require 'faraday'

module AppMap
  module Command
    UploadResponse = Struct.new(:batch_id, :scenario_uuid)

    UploadStruct = Struct.new(:config, :data, :url, :user, :org)
    class Upload < UploadStruct
      MAX_DEPTH = 12

      attr_accessor :batch_id

      def initialize(config, data, url, user, org)
        super

        # TODO: Make this an option
        @max_depth = MAX_DEPTH
      end

      def perform
        appmap = data.clone

        # If it's a list, upload it as a classMap
        if data.is_a?(Hash)
          events = data.delete('events') || []
          class_map = data.delete('classMap') || []

          pruned_events = []
          stack = []
          events.each do |evt|
            if evt['event'] == 'call'
              stack << evt
              stack_depth = stack.length
            else
              stack_depth = stack.length
              stack.pop
            end

            prune = stack_depth > @max_depth

            pruned_events << evt unless prune
          end

          warn "Pruned events to #{pruned_events.length}" if events.length > pruned_events.length

          events = pruned_events

          class_map = prune(class_map, events: events)
          appmap[:classMap] = class_map
          appmap[:events] = events
        else
          class_map = prune(data)
          appmap = { "version": AppMap::APPMAP_FORMAT_VERSION, "classMap": class_map, "events": [] }
        end

        upload_file = { user: user, org: org, data: appmap }.compact

        conn = Faraday.new(url: url)
        response = conn.post do |req|
          req.url '/api/scenarios'
          req.headers['Content-Type'] = 'application/json'
          req.headers[AppMap::BATCH_HEADER_NAME] = @batch_id if @batch_id
          req.body = JSON.generate(upload_file)
        end

        unless response.body.blank?
          message = begin
                      JSON.parse(response.body)
                    rescue JSON::ParserError => e
                      warn "Response is not valid JSON (#{e.message})"
                      nil
                    end
        end

        unless response.success?
          error = [ 'Upload failed' ]
          error << ": #{message}" if message
          raise error.join
        end

        batch_id = @batch_id || response.headers[AppMap::BATCH_HEADER_NAME]

        uuid = message['uuid']
        UploadResponse.new(batch_id, uuid)
      end

      protected

      def debug?
        ENV['DEBUG'] == 'true' || ENV['GLI_DEBUG'] == 'true'
      end

      def prune(class_map, events: nil)
        require 'appmap/algorithm/prune_class_map'
        Algorithm::PruneClassMap.new(class_map).tap do |alg|
          alg.events = events if events
          alg.logger = ->(msg) { warn msg } if debug?
        end.prune
      end
    end
  end
end

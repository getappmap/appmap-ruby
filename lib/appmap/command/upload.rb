require 'json'
require 'faraday'

module AppMap
  module Command
    UploadStruct = Struct.new(:config, :appmap, :url, :owner)

    class Upload < UploadStruct
      MAX_DEPTH = 12

      def initialize(config, appmap, url, owner)
        super

        # TODO: Make this an option to the CLI
        @max_depth = MAX_DEPTH
      end

      def perform
        # If it's a list, upload it as a classMap
        if appmap.is_a?(Hash)
          events = appmap.delete('events') || []
          class_map = appmap.delete('classMap') || []

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
          class_map = prune(appmap)
          appmap = { "classMap": class_map, "events": [] }
        end

        upload_file = { owner_id: owner, data: appmap }

        conn = Faraday.new(url: url)
        response = conn.post do |req|
          req.url '/api/scenarios'
          req.headers['Content-Type'] = 'application/json'
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

        message['uuid']
      end

      protected

      # Prune the classMap so that only functions, classes and packages which are referenced
      # by some event are retained.
      def prune(class_map, events: nil)
        # This proc counts the number of objects in the class map whose type is 'k'
        count = proc do |k, e|
          n = 0
          n += 1 if e['type'] == k
          n += (e['children'] || []).map { |child| count.call(k, child) }.reduce(0, :+)
          n
        end

        warn "Full classMap contains #{class_map.map { |m| count.call('class', m) }.reduce(0, :+)} classes"

        # Prune all the classes which fail a test.
        reject = proc do |list, test|
          list.tap do |_|
            list.each do |item|
              children = item['children']
              next unless children
              reject.call(children, test)
            end
            list.reject!(&test)
          end
        end

        if events
          locations = \
            Set.new(events.select { |e| e['event'] == 'call' }
            .map { |e| [ e['path'], e['lineno'] ].join(':') })

          # Prune all functions which aren't called
          reject.call class_map,
                      ->(e) { e['type'] == 'function' && !locations.member?(e['location']) }
        end

        # Prune all empty classes
        reject.call class_map,
                    ->(e) { e['type'] == 'class' && (e['children'] || []).empty? }

        # Prune all empty packages
        reject.call class_map,
                    ->(e) { e['type'] == 'package' && (e['children'] || []).empty? }

        warn "Pruned classMap contains #{class_map.map { |m| count.call('class', m) }.reduce(0, :+)} classes"

        class_map
      end
    end
  end
end

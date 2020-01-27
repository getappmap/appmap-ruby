module AppMap
  module Algorithm
    # Prune a class map so that only functions, classes and packages which are referenced
    # by some event are retained.
    class PruneClassMap
      attr_reader :class_map
      # Set this attribute to a function which will log algorithm events.
      attr_writer :logger
      attr_accessor :events

      # Construct the algorithm, with a class map that will be pruned in place.
      def initialize(class_map)
        @class_map = class_map
        @logger = ->(msg) {}
      end

      def perform
        # This proc counts the number of objects in the class map whose type is 'k'
        count = proc do |k, e|
          n = 0
          n += 1 if e['type'] == k
          n += (e['children'] || []).map { |child| count.call(k, child) }.reduce(0, :+)
          n
        end

        @logger.call "Full classMap contains #{class_map.map { |m| count.call('class', m) }.reduce(0, :+)} classes"

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

        @logger.call "Pruned classMap contains #{class_map.map { |m| count.call('class', m) }.reduce(0, :+)} classes"

        class_map
      end
    end
  end
end

module AppMap
  module Algorithm
    StatsStruct = Struct.new(:appmap)

    # Compute AppMap statistics.
    class Stats < StatsStruct
      Result = Struct.new(:class_frequency, :method_frequency) do
        def merge!(other)
          merge = lambda do |freq, other_freq|
            freq_by_name = freq.inject({}) do |table, entry|
              table.tap do
                table[entry.name] = entry
              end
            end
            other_freq.each do |other_entry|
              entry = freq_by_name[other_entry.name]
              if entry
                entry.count += other_entry.count
              else
                freq << other_entry
              end
            end
          end
          merge.call(class_frequency, other.class_frequency)
          merge.call(method_frequency, other.method_frequency)

          self
        end

        def sort!
          comparator = ->(a,b) { b.count <=> a.count }
          class_frequency.sort!(&comparator)
          method_frequency.sort!(&comparator)
          
          self
        end

        def limit!(limit)
          self.class_frequency = class_frequency[0...limit]
          self.method_frequency = method_frequency[0...limit]

          self
        end

        def as_text
          lines = [
            "Class frequency:",
            "----------------",
          ] + class_frequency.map(&:to_a).map(&:reverse).map { |line | line.join("\t") } + [
            "",
            "Method frequency:",
            "----------------",
          ] + method_frequency.map(&:to_a).map(&:reverse).map { |line | line.join("\t") }
          lines.join("\n")
        end
      end
      Frequency = Struct.new(:name, :count)
      
      def perform(limit: nil)
        events = appmap['events'] || []
        frequency_calc = lambda do |key_func|
          events_by_key = events.inject(Hash.new(0))  do |memo, event|
            key = key_func.call(event)
            memo.tap do
              memo[key] += 1 if key
            end
          end
          events_by_key.map do |key, count|
            Frequency.new(key, count)
          end
        end

        class_name_func = ->(event) { event['defined_class'] }
        full_name_func = lambda do |event|
          class_name = event['defined_class']
          static = event['static']
          function_name = event['method_id']
          [ class_name, static ? '.' : '#', function_name ].join if class_name && !static.nil? && function_name
        end

        class_frequency = frequency_calc.call(class_name_func)
        method_frequency = frequency_calc.call(full_name_func)

        Result.new(class_frequency, method_frequency)
      end
    end
  end
end

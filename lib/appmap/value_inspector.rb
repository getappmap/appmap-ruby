module AppMap
  module ValueInspector
    extend self

    MAX_DEPTH = 3

    def detect_size(value)
      # Don't risk calling #size on things like data-access objects, which can and will issue queries for this information.
      if value.is_a?(Array) || value.is_a?(Hash)
        value.size
      end
    end

    def detect_schema(value, max_depth: MAX_DEPTH, type_info: {}, observed_values: Set.new(), depth: 0)
      return type_info if depth == max_depth

      if value.respond_to?(:keys)
        return if observed_values.include?(value.object_id)

        observed_values << value.object_id

        properties = value.keys.select { |key| key != "" && !key.nil? }.map do |key|
          next_value = value[key]

          value_schema = begin
              { name: key, class: best_class_name(next_value) }
            rescue
              warn "Error in add_schema(#{next_value.class})", $!
              raise
            end

          detect_schema(next_value, **{ max_depth: max_depth, type_info: value_schema, observed_values: observed_values, depth: depth + 1 })
        end.compact
        type_info[:properties] = properties unless properties.empty?
      elsif value.respond_to?(:first)
        detect_schema(value.first, **{ max_depth: max_depth, type_info: type_info, observed_values: observed_values, depth: depth + 1 })
      end
      type_info
    end

    # Heuristic for dynamically defined class whose name can be nil
    def best_class_name(value)
      value_cls = value.class
      while value_cls && value_cls.name.nil?
        value_cls = value_cls.superclass
      end
      value_cls&.name || "unknown"
    end
  end
end

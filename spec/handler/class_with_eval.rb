# frozen_string_literal: true

# rubocop:disable Style/EvalWithLocation

module AppMap
  class SpecClasses
    class WithEval
      eval %(def text; 'text'; end)
    end
  end
end

# rubocop:enable Style/EvalWithLocation

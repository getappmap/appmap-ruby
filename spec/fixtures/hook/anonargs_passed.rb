# Since ruby 3.2, anonymous rest arguments can be passed as arguments,
# instead of just used in method parameters.
class AnonArgsPassed
  class << self
    def anon_rest(*)
      'anon'
    end

    def has_anon_rest_calls_anon_rest(*)
      anon_rest(*)
    end


    def non_anon_rest_first(*, arg1, arg2)
      [arg1, arg2]
    end

    def has_anon_rest_calls_non_anon_rest_first(*)
      non_anon_rest_first(*)
    end


    def non_anon_rest_last(arg1, arg2, *)
      [arg1, arg2]
    end

    def has_anon_rest_calls_non_anon_rest_last(*)
      non_anon_rest_last(*)
    end
  end
end

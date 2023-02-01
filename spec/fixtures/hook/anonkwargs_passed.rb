# Since ruby 3.2, anonymous keyword rest arguments can be passed as
# arguments, instead of just used in method parameters.
class AnonKwargsPassed
  class << self
    def kw_rest(**)
      'kwargs'
    end

    def has_kw_rest_calls_kw_rest(args, **)
      kw_rest(**)
    end

    # there's no has_kw_rest_calls_kw_rest_first because by convention
    # keyword arguments are always last

    def kw_rest_last(args)
      args
    end

    def has_kw_rest_calls_kw_rest_last(*args, **)
      kw_rest_last(**)
    end
  end
end

# Since ruby 3.2, all methods wishing to delegate keyword arguments
# through *args must now be marked with ruby2_keywords, with no
# exception.
class ArgsToKwArgs
  class << self
    def kw_rest(**kwargs)
      kwargs
    end

    # if ruby2_keywords is removed this test fails
    ruby2_keywords def has_args_calls_kwargs(*args)
      kw_rest(*args)
    end
  end
end

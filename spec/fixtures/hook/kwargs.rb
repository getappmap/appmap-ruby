class Kwargs
  class << self
    def no_kwargs(args)
      args
    end

    def has_kwrest_calls_no_kwargs(args, **kwargs)
      no_kwargs(**kwargs)
    end
  end
end

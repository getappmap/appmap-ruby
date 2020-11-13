# frozen_string_literal: true

class InstanceMethod
  def to_s
    'Instance Method fixture'
  end

  def say_default
    'default'
  end

  def say_echo(arg)
    arg.to_s
  end

  def say_kw(kw: 'kw')
    kw.to_s
  end

  def say_kws(*args, kw1:, kw2: 'kw2', **kws)
    [kw1, kw2, kws, args].join
  end

  def say_block(&block)
    yield
  end

  def say_the_time
    Time.now.to_s
  end
end

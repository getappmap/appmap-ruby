# frozen_string_literal: true

class ExceptionMethod
  def to_s
    'Exception Method fixture'
  end

  def raise_exception
    raise 'Exception occurred in raise_exception'
  end
end

# subclass from BasicObject so we don't get #to_s. Requires some
# hackery to implement the other methods normally provided by Object.
class NoToSMethod < BasicObject
  def is_a?(*args)
    return false
  end

  def class
    return ::Class
  end

  def respond_to?(*args)
    return false
  end

  def inspect
    "NoToSMethod"
  end

  def say_hello
    "hello"
  end
end

class InspectRaises < NoToSMethod
  def inspect
    ::Kernel.raise "#to_s missing, #inspect raises"
  end

  def say_hello
    "hello"
  end
end

class ToSRaises
  def to_s
    raise "#to_s raises"
  end

  def say_hello
    "hello"
  end
end

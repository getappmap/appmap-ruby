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

class ExceptionMethod
  def raise_illegal_utf8_message
    raise "809: unexpected token at 'x\x9C\xED=\x8Bv\xD3ƶ\xBF2\xB8]\xC5\xE9qdI\x96eǫ4\xA4h΅\x84\xE5z\x96\xAA\xD8\xE3\xE3D\xB2\xE4J2\x90E\xF8\xF7\xBB\xF7\xCC\xE81\x92\xE2\x88ā'"
  end
end

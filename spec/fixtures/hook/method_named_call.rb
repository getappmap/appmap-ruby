# frozen_string_literal: true

class MethodNamedCall
  def to_s
    'MethodNamedCall'
  end

  def call(a, b, c, d, e)
    [ a, b, c, d, e ].join(' ')
  end
end

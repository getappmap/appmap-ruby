# frozen_string_literal: true

class ExceptionMethod
  def to_s
    'Exception Method fixture'
  end

  def raise_exception
    raise 'Exception occurred in raise_exception'
  end
end

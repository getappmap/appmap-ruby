# frozen_string_literal: true

class ProtectedMethod
  def call_protected
    protected_method
  end

  def to_s
    'Protected Method fixture'
  end

  class << self
    def call_protected
      protected_method
    end

    protected
  
    def protected_method
      'self.protected'
    end
  end

  protected
  
  def protected_method
    'protected'
  end
end

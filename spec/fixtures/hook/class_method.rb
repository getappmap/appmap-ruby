# frozen_string_literal: true

class ClassMethod
  class << self
    def say_default
      'default'
    end
  end

  def ClassMethod.say_class_defined
    'defined with explicit class scope'
  end

  def self.say_self_defined
    'defined with self class scope'
  end
end

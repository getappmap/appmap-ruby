# frozen_string_literal: true

class SameNameMethods
  def self.say_hello
    'hello from the class'
  end

  def say_hello
    'hello from an instance'
  end

  def to_s
    'Same Name Methods fixture'
  end
end

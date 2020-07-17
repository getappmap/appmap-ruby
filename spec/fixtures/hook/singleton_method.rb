# frozen_string_literal: true

class SingletonMethod
  class << self
    def say_default
      'default'
    end
  end

  def SingletonMethod.say_class_defined
    'defined with explicit class scope'
  end

  def self.say_self_defined
    'defined with self class scope'
  end

  # When called, do_include calls +include+ to bring in the module
  # AddMethod. AddMethod defines a new instance method, which gets
  # added to the singleton class of SingletonMethod.
  def do_include
    class << self
      SingletonMethod.include(AddMethod)
    end
    self
  end
  
  def self.new_with_instance_method
    SingletonMethod.new.tap do |m|
      def m.say_instance_defined
        'defined for an instance'
      end
    end
  end
  
  def to_s
    'Singleton Method fixture'
  end
end

module AddMethod
  def self.included(base)
    base.module_eval do
      define_method "added_method" do
        _added_method
      end
    end
  end
  
  def _added_method
    'defined by including a module'
  end
end


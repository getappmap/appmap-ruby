class ExcludeTest
  def instance_method
    'instance_method'
  end

  class << self
    def singleton_method
      'singleton_method'
    end
  end

  def self.cls_method
    'class_method'
  end
end

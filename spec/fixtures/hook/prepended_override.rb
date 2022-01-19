
module PrependedModule
  def say_hello
    'please allow me to ' + super
  end
end

class PrependedClass
  prepend PrependedModule

  def say_hello
    'introduce myself'
  end
end

require 'active_support'

class Record
  include ActiveSupport::Callbacks
  define_callbacks :save

  def save
    run_callbacks :save do
      puts "- save"
    end
  end
end

class PersonRecord < Record
  set_callback :save, :before, :saving_message
  def saving_message
    puts "saving..."
  end

  set_callback :save, :after do |object|
    puts "saved"
  end
end

person = PersonRecord.new
person.save

p person.__callbacks[:save].instance_variables
p person.__callbacks[:save].chain

# person.__callbacks[:save].methods.each { |method|
#   p person.__callbacks[:save][method]
# }

#p person.__callbacks

# person.__callbacks.each { |callback|
#   callback.each { |c|
#     p c
#   }
#   #p callback
# }


# frozen_string_literal: true

When('I say hello') do
  @message = Hello.new.say_hello
end

Then('the message is hello') do
  raise 'Wrong message!' unless @message == 'Hello!'
end

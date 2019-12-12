require 'rspec'
require 'appmap/rspec'
require 'hello'

describe Hello, appmap: 'hello' do
  it 'says hello', appmap: 'speak' do
    expect(Hello.new.say_hello).to eq('Hello!')
  end
end

require 'rspec'
require 'appmap/rspec'
require 'hello'

describe Hello, appmap: true do
  it 'says hello' do
    expect(Hello.new.say_hello).to eq('Hello!')
  end
end

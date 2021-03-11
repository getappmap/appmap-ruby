require 'rspec'
require 'appmap/rspec'
require 'hello'

describe Hello do
  it 'says hello' do
    expect(Hello.new.say_hello).to eq('Hello!')
  end
end

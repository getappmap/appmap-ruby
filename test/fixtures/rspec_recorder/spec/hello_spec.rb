require 'rspec'
require 'appmap/rspec'
require 'hello'

describe Hello, feature_group: 'Hello' do
  it 'says hello', feature: 'Say hello', appmap: true do
    expect(Hello.new.say_hello).to eq('Hello!')
  end
end

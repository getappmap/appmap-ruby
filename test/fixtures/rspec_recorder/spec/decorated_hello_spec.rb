require 'rspec'
require 'appmap/rspec'
require 'hello'

describe Hello, feature_group: 'Saying hello' do
  it 'says hello', feature: 'Speak hello', appmap: true do
    expect(Hello.new.say_hello).to eq('Hello!')
  end
end

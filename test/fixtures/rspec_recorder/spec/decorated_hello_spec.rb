require 'rspec'
require 'appmap/rspec'
require 'hello'

describe Hello do
  before do
    # Trick appmap-ruby into thinking we're a Rails app.
    stub_const('Rails', double('rails', version: 'fake.0'))
  end

  # The order of these examples is important. The tests check the
  # appmap for 'says hello', and we want another example to get run
  # before it.
  it 'does not say goodbye' do
    expect(Hello.new.say_hello).not_to eq('Goodbye!')
  end

  it 'says hello' do
    expect(Hello.new.say_hello).to eq('Hello!')
  end
end

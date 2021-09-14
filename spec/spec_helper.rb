require 'rspec'
require 'net/http'
require 'json'
require 'yaml'
require 'English'
require 'byebug'
require 'webdrivers/chromedriver'

# Disable default initialization of AppMap
ENV['APPMAP_INITIALIZE'] = 'false'

require 'appmap'

RSpec.configure do |config|
  config.example_status_persistence_file_path = "tmp/rspec_failed_examples.txt"
end

# Re-run the Rails specs without re-generating the data. This is useful for efficiently enhancing and
# debugging the test itself.
def use_existing_data?
  ENV['USE_EXISTING_DATA'] == 'true'
end

def ruby_2?
  RUBY_VERSION.split('.')[0].to_i == 2
end

shared_context 'collect events' do
  def collect_events(tracer)
    [].tap do |events|
      while tracer.event?
        events << tracer.next_event.to_h
      end
    end.map(&AppMap::Util.method(:sanitize_event))
  end
end

require 'spec_helper'
require 'rack'
require 'rack/handler/webrick'

class HelloWorldApp
  def call(env)
    req = Rack::Request.new(env)
    case req.path_info
    when /hello/
      [200, {"Content-Type" => "text/html"}, ["Hello World!"]]
    when /goodbye/  
      [500, {"Content-Type" => "text/html"}, ["Goodbye Cruel World!"]]
    else
      [404, {"Content-Type" => "text/html"}, ["I'm Lost!"]]
    end
  end
end

describe 'Net::HTTP handler' do
  def get_hello
    http = Net::HTTP.new('localhost', 19292)
    http.get '/hello'
  end
  
  before(:all) do
    @rack_thread = Thread.new do
      Rack::Handler::WEBrick.run HelloWorldApp.new, Port: 19292
    end
    10.times do
      sleep 0.1
      break if get_hello.code.to_i == 200
    end
    raise "Web server didn't start" unless get_hello.code.to_i == 200
  end

  after(:all) do
    @rack_thread.kill
  end

  def collect_events(tracer)
    [].tap do |events|
      while tracer.event?
        events << tracer.next_event.to_h
      end
    end.map(&AppMap::Util.method(:sanitize_event))
  end

  context 'with trace enabled' do
    let(:configuration) { AppMap::Config.new('record_net_http_spec', []) }
    before do
      AppMap.configuration = configuration
      AppMap::Hook.new(configuration).enable

      @tracer = AppMap.tracing.trace
      AppMap::Event.reset_id_counter
    end

    after do
      AppMap.configuration = nil
    end
    
    it 'records a GET request' do
      get_hello
  
      AppMap.tracing.delete(@tracer)
  
      puts JSON.pretty_generate(collect_events(@tracer))
    end
  end
end

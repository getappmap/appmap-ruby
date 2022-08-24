require 'spec_helper'
require 'diffy'
require 'rack'
require 'webrick'
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
  include_context 'collect events'

  def get_hello(params: nil)
    http = Net::HTTP.new('localhost', 19292)
    http.get [ '/hello', params ].compact.join('?')
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

  def start_recording
    AppMap.configuration = configuration
    AppMap::Hook.new(configuration).enable

    @tracer = AppMap.tracing.trace
    AppMap::Event.reset_id_counter
  end

  def record(&block)
    start_recording
    begin
      yield
    ensure
      stop_recording
    end
  end

  def stop_recording
    AppMap.tracing.delete(@tracer)
  end

  context 'with trace enabled' do
    let(:configuration) { AppMap::Config.new('record_net_http_spec') }

    after do
      AppMap.configuration = nil
    end
    
    describe 'GET request' do
      it 'with a single query parameter' do
        record do
          get_hello(params: 'msg=hi')
        end

        events = collect_events(@tracer).to_yaml
        expect(Diffy::Diff.new(<<~EVENTS, events).to_s).to eq('')
        ---
        - :id: 1
          :event: :call
          :http_client_request:
            :request_method: GET
            :url: http://localhost:19292/hello
            :headers:
              Accept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3
              Accept: "*/*"
              User-Agent: Ruby
              Connection: close
          :message:
          - :name: msg
            :class: String
            :value: hi
        - :id: 2
          :event: :return
          :parent_id: 1
          :http_client_response:
            :status_code: 200
            :headers:
              Content-Type: text/html
              Server: WEBrick
              Date: "<instanceof date>"
              Content-Length: '12'
              Connection: close
        EVENTS
      end

      it 'with a multi-valued query parameter' do
        record do
          get_hello(params: 'ary[]=1&ary[]=2')
        end

        event = collect_events(@tracer).first.to_yaml
        expect(Diffy::Diff.new(<<~EVENT, event).to_s).to eq('')
        ---
        :id: 1
        :event: :call
        :http_client_request:
          :request_method: GET
          :url: http://localhost:19292/hello
          :headers:
            Accept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3
            Accept: "*/*"
            User-Agent: Ruby
            Connection: close
        :message:
        - :name: ary
          :class: Array
          :value: '["1", "2"]'
        EVENT
      end

      it 'with a URL encoded query parameter' do
        msg = 'foo/bar?baz'
        record do
          get_hello(params: "msg=#{CGI.escape msg}")
        end

        event = collect_events(@tracer).first.to_yaml
        expect(Diffy::Diff.new(<<~EVENT, event).to_s).to eq('')
        ---
        :id: 1
        :event: :call
        :http_client_request:
          :request_method: GET
          :url: http://localhost:19292/hello
          :headers:
            Accept-Encoding: gzip;q=1.0,deflate;q=0.6,identity;q=0.3
            Accept: "*/*"
            User-Agent: Ruby
            Connection: close
        :message:
        - :name: msg
          :class: String
          :value: #{msg}
        EVENT
      end
    end
  end
end

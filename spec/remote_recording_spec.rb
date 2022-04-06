require 'rails_spec_helper'

require 'random-port'

require 'net/http'
require 'socket'

describe 'remote recording', :order => :defined do
  include_context 'Rails app pg database', 'spec/fixtures/rails6_users_app' do
    before(:all) do
      @service_port = RandomPort::Pool::SINGLETON.acquire
      @app.prepare_db
      @server = @app.spawn_cmd \
        "./bin/rails server -p #{@service_port}",
        'ORM_MODULE' => 'sequel',
        'APPMAP' => 'true'

      uri = URI("http://localhost:#{@service_port}/health")

      100.times do
        Net::HTTP.get(uri)
        break
      rescue Errno::ECONNREFUSED
        sleep 0.1
      end
    end

    def json_body(res)
      JSON.parse(res.body).deep_symbolize_keys
    end

    after(:all) do
      if @server
        Process.kill 'INT', @server
        Process.wait @server
      end
    end

    let(:service_address) { URI("http://localhost:#{@service_port}") }
    let(:users_path) { '/users' }
    let(:record_path) { '/_appmap/record' }

    it 'returns the recording status' do
      res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
        http.request(Net::HTTP::Get.new(record_path))
      }

      expect(res).to be_a(Net::HTTPOK)
      expect(res['Content-Type']).to eq('application/json')
      expect(json_body(res)).to eq(enabled: false)
    end

    it 'starts a new recording session' do
      res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
        http.request(Net::HTTP::Post.new(record_path))
      }

      expect(res).to be_a(Net::HTTPOK)
    end

    it 'reflects the recording status' do
      res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
        http.request(Net::HTTP::Get.new(record_path))
      }

      expect(res).to be_a(Net::HTTPOK)
      expect(res['Content-Type']).to eq('application/json')
      expect(json_body(res)).to eq(enabled: true)
    end

    it 'fails to start a new recording session while recording is already active' do
      res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
        http.request(Net::HTTP::Post.new(record_path))
      }

      expect(res).to be_a(Net::HTTPConflict)
    end

    it 'stops recording' do
      # Generate some events
      Net::HTTP.start(service_address.hostname, service_address.port) { |http|
        http.request(Net::HTTP::Get.new(users_path) )
      }

      res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
        http.request(Net::HTTP::Delete.new(record_path))
      }

      expect(res).to be_a(Net::HTTPOK)
      expect(res['Content-Type']).to eq('application/json')

      data = json_body(res)
      expect(data[:metadata]).to be_truthy
      expect(data[:classMap].length).to be > 0
      expect(data[:events].length).to be > 0
    end

    it 'fails to stop recording if there is no active recording session' do
      res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
        http.request(Net::HTTP::Delete.new(record_path))
      }

      expect(res).to be_a(Net::HTTPNotFound)
    end
  end
end

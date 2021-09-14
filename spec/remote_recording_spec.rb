require 'rails_spec_helper'
require 'net/http'
require 'socket'

describe 'remote recording', :order => :defined do
  include_context 'Rails app pg database', 'spec/fixtures/rails6_users_app' do
    before(:all) do
      fixture_dir = 'spec/fixtures/rails6_users_app'
      start_cmd = 'docker-compose up -d app'
      run_cmd({ 'ORM_MODULE' => 'sequel', 'APPMAP' => 'true' }, start_cmd, chdir: fixture_dir)
      Dir.chdir fixture_dir do
        wait_for_container 'app'
      end

      port_cmd = 'docker-compose port app 3000'
      port_out, = run_cmd port_cmd, chdir: fixture_dir
      @service_port = port_out.strip.split(':')[1]

      service_running = false
      retry_count = 0
      uri = URI("http://localhost:#{@service_port}/health")

      until service_running
        sleep(0.25)
        begin
          res = Net::HTTP.start(uri.hostname, uri.port) do |http|
            http.request(Net::HTTP::Get.new(uri))
          end

          status = res.response.code.to_i
          service_running = true if status >= 200 && status < 300

          # give up after a certain error threshold is met
          # we don't want to wait forever if there's an unrecoverable issue
          raise 'gave up waiting on fixture service' if (retry_count += 1) == 10
        rescue Errno::ETIMEDOUT, Errno::ECONNRESET, EOFError
          $stderr.print('.')
        end
      end
    end

    def json_body(res)
      JSON.parse(res.body).deep_symbolize_keys
    end

    after(:all) do
      fixture_dir = 'spec/fixtures/rails6_users_app'
      run_cmd 'docker-compose rm -fs app', chdir: fixture_dir
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

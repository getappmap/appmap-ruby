require 'rails_spec_helper'
require 'net/http'
require 'socket'

describe 'remote recording', :order => :defined do
  before(:all) { @fixture_dir = 'spec/fixtures/rails_users_app' }
  include_context 'Rails app pg database'
  
  before(:all) do
    # We should really leave it to Docker to pick a random port for us, but right now we have no
    # ability to parse the output of `docker port`. This should be sufficient for now.
    @service_port = rand(30000..60000)

    cmd = 'docker-compose run' \
      ' -d' \
      " -p #{@service_port}:3000" \
      ' -e ORM_MODULE=sequel' \
      ' -e APPMAP=true' \
      ' app'

    run_cmd cmd, chdir: @fixture_dir

    service_running = false
    retry_count = 0
    uri = URI("http://localhost:#{@service_port}/health")

    until service_running
      begin
        res = Net::HTTP.start(uri.hostname, uri.port) do |http|
          http.request(Net::HTTP::Get.new(uri))
        end

        service_running = true if res.instance_of?(Net::HTTPNoContent);

        # give up after a certain error threshold is met
        # we don't want to wait forever if there's an unrecoverable issue
        raise "gave up waiting on fixture service" if (retry_count += 1) == 10
      rescue Errno::ETIMEDOUT, Errno::ECONNRESET, EOFError => e
        sleep(1.0)
      end
    end
  end

  def json_body(res)
    JSON.parse(res.body).deep_symbolize_keys
  end

  after(:all) do
    run_cmd 'docker-compose rm -fs app', chdir: @fixture_dir
  end

  let(:service_address) { URI("http://localhost:#{@service_port}") }
  let(:users_path) { "/users" }
  let(:record_path) { "/_appmap/record" }

  it 'returns the recording status' do
    res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request( Net::HTTP::Get.new(record_path) )
    }

    expect(res).to be_a(Net::HTTPOK)
    expect(res['Content-Type']).to eq('application/json')
    expect(json_body(res)).to eq(enabled: false)
  end

  it 'starts a new recording session' do
    res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request( Net::HTTP::Post.new(record_path) )
    }

    expect(res).to be_a(Net::HTTPOK)
  end

  it 'reflects the recording status' do
    res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request( Net::HTTP::Get.new(record_path) )
    }

    expect(res).to be_a(Net::HTTPOK)
    expect(res['Content-Type']).to eq('application/json')
    expect(json_body(res)).to eq(enabled: true)
  end

  it 'fails to start a new recording session while recording is already active' do
    res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request( Net::HTTP::Post.new(record_path) )
    }

    expect(res).to be_a(Net::HTTPConflict)
  end

  it 'stops recording' do
    # Generate some events
    Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request( Net::HTTP::Get.new(users_path) )
    }

    res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request( Net::HTTP::Delete.new(record_path) )
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
      http.request( Net::HTTP::Delete.new(record_path) )
    }

    expect(res).to be_a(Net::HTTPNotFound)
  end
end

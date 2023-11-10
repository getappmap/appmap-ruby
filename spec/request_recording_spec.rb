require "rails_spec_helper"

require "net/http"

describe "request recording", order: :defined do
  include_context "Rails app pg database", "spec/fixtures/rails6_users_app"
  include_context "Rails app service running"

  before(:all) do
    @service_port, @server = start_server(rails_app_environment: {"ORM_MODULE" => "sequel", "APPMAP_RECORD_REMOTE" => "false"})
  end
  after(:all) do
    stop_server(@server)
  end

  let(:service_address) { URI("http://localhost:#{@service_port}") }

  it "creates an AppMap for a request" do
    # Generate some events
    Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request(Net::HTTP::Get.new(users_path))
    }
    Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request(Net::HTTP::Get.new(users_path))
    }
    res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
      http.request(Net::HTTP::Get.new(users_path))
    }

    expect(res).to be_a(Net::HTTPOK)
    expect(res).to include("appmap-file-name")
    appmap_file_name = res["AppMap-File-Name"]
    expect(File.exist?(appmap_file_name)).to be(true)
    appmap = JSON.parse(File.read(appmap_file_name))
    # Every event should come from the same thread
    expect(appmap["events"].map { |evt| evt["thread_id"] }.uniq.length).to eq(1)
    # AppMap should contain only one request and response
    expect(appmap["events"].select { |evt| evt["http_server_request"] }.length).to eq(1)
    expect(appmap["events"].select { |evt| evt["http_server_response"] }.length).to eq(1)
  end
end

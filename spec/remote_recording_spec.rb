require "rails_spec_helper"

require "net/http"

describe "remote recording", order: :defined do
  def json_body(res)
    JSON.parse(res.body).deep_symbolize_keys
  end

  rails_versions.each do |rails_version|
    context "with rails #{rails_version}" do
      include_context "rails app", rails_version
      include_context "Rails app service running"

      before(:all) do
        rails_app_environment = {"ORM_MODULE" => "sequel", "APPMAP_RECORD_REQUESTS" => "false"}
        command_options = if testing_ruby_2?
          {}
        else
          {u: "puma"}
        end

        @service_port, @server = start_server(rails_app_environment: rails_app_environment, command_options: command_options)
      end
      after(:all) do
        stop_server(@server)
      end

      let(:service_address) { URI("http://localhost:#{@service_port}") }
      let(:record_path) { "/_appmap/record" }

      it "returns the recording status" do
        res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
          http.request(Net::HTTP::Get.new(record_path))
        }

        expect(res).to be_a(Net::HTTPOK)
        expect(res["Content-Type"]).to eq("application/json")
        expect(json_body(res)).to eq(enabled: false)
      end

      it "starts a new recording session" do
        res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
          http.request(Net::HTTP::Post.new(record_path))
        }

        expect(res).to be_a(Net::HTTPOK)
      end

      it "reflects the recording status" do
        res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
          http.request(Net::HTTP::Get.new(record_path))
        }

        expect(res).to be_a(Net::HTTPOK)
        expect(res["Content-Type"]).to eq("application/json")
        expect(json_body(res)).to eq(enabled: true)
      end

      it "fails to start a new recording session while recording is already active" do
        res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
          http.request(Net::HTTP::Post.new(record_path))
        }

        expect(res).to be_a(Net::HTTPConflict)
      end

      it "stops recording" do
        users_res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
          http.request(Net::HTTP::Get.new(users_path))
        }
        # Request recording is not enabled by environment variable
        expect(users_res).to_not include("appmap-file-name")

        res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
          http.request(Net::HTTP::Delete.new(record_path))
        }

        expect(res).to be_a(Net::HTTPOK)
        expect(res["Content-Type"]).to eq("application/json")

        data = json_body(res)
        expect(data[:metadata]).to be_truthy
        expect(data[:classMap].length).to be > 0
        expect(data[:events].length).to be > 0
      end

      it "fails to stop recording if there is no active recording session" do
        res = Net::HTTP.start(service_address.hostname, service_address.port) { |http|
          http.request(Net::HTTP::Delete.new(record_path))
        }

        expect(res).to be_a(Net::HTTPNotFound)
      end
    end
  end
end

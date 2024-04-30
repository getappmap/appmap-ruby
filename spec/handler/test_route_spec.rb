require "spec_helper"
require_relative "../../lib/appmap/handler/rails/test_route"

RSpec.describe AppMap::Handler::Rails do
  let(:request) { double("request", path_info: "/test_path") }
  let(:app) { double("app") }

  after do
    described_class.instance_variable_set(:@test_route_warned, false)
  end

  describe ".test_route" do
    context "when matches? is successfully invoked" do
      before do
        allow(app).to receive(:matches?).with(request).and_return(true)
      end

      it "returns true" do
        result = described_class.test_route(app, request)
        expect(result).to be true
      end
    end

    context "when matches? raises an error" do
      before do
        allow(app).to receive(:matches?).with(request).and_raise("Route matching error")
      end

      it "rescues the error and returns false" do
        expect { described_class.test_route(app, request) }.to output(/Failed to match route/).to_stderr
        result = described_class.test_route(app, request)
        expect(result).to be false
      end

      context "multiple times" do
        let(:warnings) { [] }
        before do
          allow(Kernel).to receive(:warn) do |message|
            warnings << message
          end
        end

        it "logs the warning only once" do
          expect {
            2.times do
              described_class.test_route(app, request)
            end
          }.to output(<<~MSG).to_stderr
            Notice: Failed to match route for /test_path: Route matching error
            Notice: A solution for this problem is forthcoming, see https://github.com/getappmap/appmap-ruby/issues/360
          MSG
        end
      end
    end
  end
end

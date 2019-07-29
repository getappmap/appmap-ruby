require 'rails_spec_helper'

describe 'AppMap tracer via Railtie' do
  include_examples 'Rails app pg database'

  let(:env) { {} }

  let(:cmd) { %(docker-compose run --rm -e APPMAP app ./bin/rails r "puts Rails.configuration.appmap.enabled.inspect") }
  let(:command_capture2) do
    require 'open3'
    Open3.capture2(env, cmd, chdir: 'spec/fixtures/rails_users_app').tap do |result|
      raise 'Failed to run rails_users_app container' unless result[1] == 0
    end
  end
  let(:command_output) { command_capture2[0].strip }
  let(:command_result) { command_capture2[1] }

  it 'is disabled by default' do
    expect(command_output).to eq('nil')
  end

  describe 'with APPMAP=true' do
    let(:env) { { 'APPMAP' => 'true' } }
    it 'is enabled' do
      expect(command_output).to eq('true')
    end
  end
end

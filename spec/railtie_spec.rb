require 'rails_spec_helper'

describe 'AppMap tracer via Railtie' do
  include_context 'Rails app pg database', 'spec/fixtures/rails5_users_app' do 
    let(:env) { {} }

    let(:cmd) { %(docker-compose run --rm -e RAILS_ENV -e APPMAP app ./bin/rails r "puts Rails.configuration.appmap.enabled.inspect") }
    let(:command_capture2) do
      require 'open3'
      Open3.capture3(env, cmd, chdir: fixture_dir).tap do |result|
        unless result[2] == 0
          warn <<~STDERR
            Failed to run rails5_users_app container
            <<< Output:
            #{result[0]}
            #{result[1]}
            >>> End of output
          STDERR
          raise 'Failed to run rails5_users_app container'
        end
      end
    end
    let(:command_output) { command_capture2[0].strip }
    let(:command_result) { command_capture2[2] }

    it 'is disabled by default' do
      expect(command_output).to eq('nil')
    end

    describe 'with APPMAP=true' do
      let(:env) { { 'APPMAP' => 'true' } }
      it 'is enabled' do
        expect(command_output.split("\n")).to include('true')
      end
      context 'and RAILS_ENV=test' do
        let(:env) { { 'APPMAP' => 'true', 'RAILS_ENV' => 'test' } }
        it 'is disabled' do
          expect(command_output).to eq('nil')
        end
      end
    end
  end
end

require 'rails_spec_helper'

describe 'AppMap tracer via Railtie' do
  include_context 'Rails app pg database', 'spec/fixtures/rails6_users_app' do 
    let(:env) { {} }

    let(:cmd) { %(docker-compose run --rm -e RAILS_ENV=development -e APPMAP app ./bin/rails r "puts AppMap.instance_variable_get('@configuration').nil?") }
    let(:command_capture2) do
      require 'open3'
      Open3.capture3(env, cmd, chdir: fixture_dir).tap do |result|
        unless result[2] == 0
          warn <<~STDERR
            Failed to run rails6_users_app container
            <<< Output:
            #{result[0]}
            #{result[1]}
            >>> End of output
          STDERR
          raise 'Failed to run rails6_users_app container'
        end
      end
    end
    let(:command_output) { command_capture2[0].strip }
    let(:command_result) { command_capture2[2] }

    describe 'with APPMAP=false' do
      let(:env) { { 'APPMAP' => 'false' } }
      it 'is disabled' do
        expect(command_output).to eq('true')
      end
    end
    describe 'with APPMAP=true' do
      let(:env) { { 'APPMAP' => 'true' } }
      it 'is enabled' do
        expect(command_output).to eq('false')
      end
    end
  end
end

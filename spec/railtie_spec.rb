require 'rails_spec_helper'

describe 'AppMap tracer via Railtie' do
  include_context 'Rails app pg database', 'spec/fixtures/rails6_users_app' do
    let(:env) { {} }

    let(:command_output) do
      app.prepare_db
      stdout, stderr, = app.capture_cmd(%{./bin/rails r "puts AppMap.instance_variable_get('@configuration').nil?"}, env)
      stdout.strip
    end

    describe 'with APPMAP=false' do
      let(:env) { { 'APPMAP' => 'false' } }
      it 'is disabled' do
        expect(command_output).to eq('true')
      end
    end
    describe 'without APPMAP=false' do
      let(:env) { {} }
      it 'is enabled' do
        expect(command_output).to eq('false')
      end
    end
  end
end

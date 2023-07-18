# frozen_string_literal: true

require 'spec_helper'
require 'appmap/detect_enabled'

describe AppMap::DetectEnabled do
  before(:each) { AppMap::DetectEnabled.clear_cache }

  describe 'enabled?' do
    nil_scenarios = {
      disabled: [[], %w[APPMAP=false RAILS_ENV=development]],
      enabled: [%w[APPMAP=true], %w[RAILS_ENV=development], %w[APP_ENV=development]]
    }

    http_scenarios = {
      disabled: [[], %w[RAILS_ENV=test], %w[APPMAP=false RAILS_ENV=development],
        %w[APPMAP_RECORD_@=false RAILS_ENV=development]],
      enabled: [%w[APPMAP=true], %w[APPMAP_RECORD_@=true], %w[RAILS_ENV=development], %w[APP_ENV=development]]
    }

    test_scenarios = {
      disabled: [%w[APPMAP_RECORD_@=false], %w[APPMAP=true APPMAP_RECORD_@=false]],
      enabled: [[], %w[APPMAP=true], %w[APPMAP_RECORD_@=true], %w[RAILS_ENV=test], %w[APP_ENV=development]]
    }

    def self.describe_method(recording_method, disabled:, enabled:)
      describe "with #{recording_method || 'nil'} recording method" do
        let(:recording_method) { recording_method }
        disabled.each { |env| env_example env, recording_method, false }
        enabled.each { |env| env_example env, recording_method, true }
      end
    end

    def self.env_example(env, recording_method, enabled)
      env = env.map { |e| e.sub '@', recording_method.to_s.upcase }
      it "is #{enabled ? 'enabled' : 'disabled'} with #{env.join ' '}" do
        stub_const 'ENV', (env.to_h { |e| e.split '=' })
        expect(AppMap::DetectEnabled.new(recording_method))
          .send enabled ? :to : :to_not, be_enabled
      end
    end

    describe_method nil, **nil_scenarios
    %i[remote requests].each { |m| describe_method m, **http_scenarios }
    %i[rspec minitest cucumber].each { |m| describe_method m, **test_scenarios }
  end

  shared_examples 'warns about' do |recording_method|
    it recording_method do
      AppMap::DetectEnabled.discourage_conflicting_recording_methods recording_method.to_sym
      expect(AppMap::DetectEnabled).to have_received(:warn).with(/both 'requests' and '#{recording_method}'/)
      expect(AppMap::DetectEnabled).to_not have_received(:warn).with(/The environment contains APPMAP=true/)
    end
  end

  shared_examples 'does not warn about' do |recording_method|
    it recording_method do
      AppMap::DetectEnabled.discourage_conflicting_recording_methods recording_method.to_sym
      expect(AppMap::DetectEnabled).to_not have_received(:warn).with(/both 'requests' and '#{recording_method}'/)
      expect(AppMap::DetectEnabled).to_not have_received(:warn).with(/The environment contains APPMAP=true/)
    end
  end

  describe 'discourage_conflicting_recording_methods' do
    before(:each) do
      allow(AppMap::DetectEnabled).to receive(:warn)
    end

    describe 'when APPMAP_RECORD_MINITEST (only)' do
      before(:each) do
        stub_const 'ENV', { 'APPMAP_RECORD_MINITEST' => 'true' }
      end
      it_should_behave_like 'does not warn about', :minitest
    end

    describe 'when APPMAP_RECORD_CUCUMBER (only)' do
      before(:each) do
        stub_const 'ENV', { 'APPMAP_RECORD_CUCUMBER' => 'true' }
      end
      it_should_behave_like 'does not warn about', :cucumber
    end

    describe 'when APPMAP_RECORD_RSPEC (only)' do
      before(:each) do
        stub_const 'ENV', { 'APPMAP_RECORD_RSPEC' => 'true' }
      end

      it_should_behave_like 'does not warn about', :rspec
    end

    describe 'when APPMAP_RECORD_RSPEC and APPMAP_RECORD_REQUESTS' do
      before(:each) do
        stub_const 'ENV', { 'APPMAP_RECORD_RSPEC' => 'true', 'APPMAP_RECORD_REQUESTS' => 'true' }
      end

      it_should_behave_like 'warns about', :rspec

      describe 'and APPMAP=true' do
        before(:each) do
          stub_const 'ENV', { 'APPMAP_RECORD_RSPEC' => 'true', 'APPMAP_RECORD_REQUESTS' => 'true' }
        end

        it 'warns additionally' do
          AppMap::DetectEnabled.discourage_conflicting_recording_methods :rspec
          expect(AppMap::DetectEnabled).to have_received(:warn).with(/both 'requests' and 'rspec'/)
          expect(AppMap::DetectEnabled).to_not have_received(:warn).with(/The environment contains APPMAP=true/)
        end
      end
    end

    describe 'when APPMAP_RECORD_MINITEST and APPMAP_RECORD_REQUESTS' do
      before(:each) do
        stub_const 'ENV', { 'APPMAP_RECORD_MINITEST' => 'true', 'APPMAP_RECORD_REQUESTS' => 'true' }
      end

      it_should_behave_like 'warns about', :minitest
    end

    describe 'when APPMAP_RECORD_CUCUMBER and APPMAP_RECORD_REQUESTS' do
      before(:each) do
        stub_const 'ENV', { 'APPMAP_RECORD_CUCUMBER' => 'true', 'APPMAP_RECORD_REQUESTS' => 'true' }
      end

      it_should_behave_like 'warns about', :cucumber
    end
  end
end

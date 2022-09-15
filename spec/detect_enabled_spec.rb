# frozen_string_literal: true

require 'spec_helper'
require 'appmap/detect_enabled'

describe AppMap::DetectEnabled do
  before(:each) { AppMap::DetectEnabled.clear_cache }

  shared_examples_for 'disabled' do
    it do
      expect(AppMap::DetectEnabled.new(recording_method).enabled?).to be(false)
    end
  end
  shared_examples_for 'enabled' do
    it do
      expect(AppMap::DetectEnabled.new(recording_method).enabled?).to be(true)
    end
  end

  describe 'recording_method' do
    describe 'nil' do
      let(:recording_method) { nil }
      it_should_behave_like 'disabled'

      describe 'APPMAP=true' do
        before(:each) do
          stub_const('ENV', ENV.to_hash.merge('APPMAP' => 'true'))
        end
        it_should_behave_like 'enabled'
      end
      describe 'RAILS_ENV=development' do
        before(:each) do
          stub_const('ENV', ENV.to_hash.merge('RAILS_ENV' => 'development'))
        end
        it_should_behave_like 'enabled'
      end
      describe 'APP_ENV=development' do
        before(:each) do
          stub_const('ENV', ENV.to_hash.merge('APP_ENV' => 'development'))
        end
        it_should_behave_like 'enabled'
      end
      describe 'APPMAP=false and RAILS_ENV=development' do
        before(:each) do
          stub_const('ENV', ENV.to_hash.merge('APPMAP' => 'false', 'RAILS_ENV' => 'development'))
        end
        it_should_behave_like 'disabled'
      end
    end

    %w[remote requests].each do |recording_method|
      describe recording_method do
        let(:recording_method) { recording_method.to_sym }
        it_should_behave_like 'disabled'

        describe 'APPMAP=true' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('APPMAP' => 'true'))
          end
          it_should_behave_like 'enabled'
        end
        describe 'APPMAP_RECORD_<recording_method>=true' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge("APPMAP_RECORD_#{recording_method.upcase}" => 'true'))
          end
          it_should_behave_like 'enabled'
        end
        describe 'RAILS_ENV=development' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('RAILS_ENV' => 'development'))
          end
          it_should_behave_like 'enabled'
        end
        describe 'APP_ENV=development' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('APP_ENV' => 'development'))
          end
          it_should_behave_like 'enabled'
        end
        describe 'RAILS_ENV=test' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('RAILS_ENV' => 'test'))
          end
          it_should_behave_like 'disabled'
        end
        describe 'APPMAP=false and RAILS_ENV=development' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('APPMAP' => 'false', 'RAILS_ENV' => 'development'))
          end
          it_should_behave_like 'disabled'
        end
        describe 'APPMAP_RECORD_<recording_method>=false and RAILS_ENV=development' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge("APPMAP_RECORD_#{recording_method.upcase}" => 'false', 'RAILS_ENV' => 'development'))
          end
          it_should_behave_like 'disabled'
        end
      end
    end

    %w[rspec minitest cucumber].each do |test_framework|
      describe test_framework do
        let(:recording_method) { test_framework.to_sym }
        it_should_behave_like 'disabled'

        describe 'APPMAP=true' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('APPMAP' => 'true'))
          end
          it_should_behave_like 'enabled'
        end
        describe 'APPMAP_RECORD_<framework>=true' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge("APPMAP_RECORD_#{test_framework.upcase}" => 'true'))
          end
          it_should_behave_like 'enabled'
        end
        describe 'RAILS_ENV=development' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('RAILS_ENV' => 'development'))
          end
          it_should_behave_like 'disabled'
        end
        describe 'RAILS_ENV=test' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('RAILS_ENV' => 'test'))
          end
          it_should_behave_like 'enabled'
        end
        describe 'APP_ENV=test' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('APP_ENV' => 'test'))
          end
          it_should_behave_like 'enabled'
        end
        describe 'APPMAP=false and RAILS_ENV=development' do
          before(:each) do
            stub_const('ENV', ENV.to_hash.merge('APPMAP' => 'false', 'RAILS_ENV' => 'development'))
          end
          it_should_behave_like 'disabled'
        end
        end
    end
  end
end

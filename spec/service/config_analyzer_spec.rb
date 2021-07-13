# frozen_string_literal: true

require 'spec_helper'
require 'appmap/service/config_analyzer'

describe AppMap::Service::ConfigAnalyzer do
  subject { described_class.new(config_file) }

  context 'with non-existing config' do
    let(:config_file) { 'spec/fixtures/config/non_existing_config.yml'}

    describe '.app_name' do
      it 'returns nil' do
        expect(subject.app_name).to be_nil
      end
    end

    describe '.is_valid?' do
      it 'returns false' do
        expect(subject.valid?).to be_falsey
      end
    end

    describe '.is_present?' do
      it 'returns false' do
        expect(subject.present?).to be_falsey
      end
    end
  end

  context 'with valid but non rails config' do
    let(:config_file) { 'spec/fixtures/config/valid_config.yml'}

    describe '.app_name' do
      it 'returns app name value from config' do
        expect(subject.app_name).to eq('appmap')
      end
    end

    describe '.is_valid?' do
      it 'returns true' do
        expect(subject.valid?).to be_falsey
      end
    end

    describe '.is_present?' do
      it 'returns true' do
        expect(subject.present?).to be_truthy
      end
    end
  end

  context 'with invalid YAML config' do
    let(:config_file) { 'spec/fixtures/config/invalid_yaml_config.yml'}

    describe '.app_name' do
      it 'returns app name value from config' do
        expect(subject.app_name).to be_nil
      end
    end

    describe '.is_valid?' do
      it 'returns false' do
        expect(subject.valid?).to be_falsey
      end
    end

    describe '.is_present?' do
      it 'return true' do
        expect(subject.present?).to be_truthy
      end
    end
  end

  context 'with incomplete config' do
    let(:config_file) { 'spec/fixtures/config/incomplete_config.yml'}

    describe '.app_name' do
      it 'returns nil' do
        expect(subject.app_name).to eq('app')
      end
    end

    describe '.is_valid?' do
      it 'guesses paths and returns true ' do
        expect(subject.valid?).to be_falsey
      end
    end

    describe '.is_present?' do
      it 'returns true' do
        expect(subject.present?).to be_truthy
      end
    end
  end
end

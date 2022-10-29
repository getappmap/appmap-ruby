# frozen_string_literal: true

require 'spec_helper'
require 'appmap/service/config_analyzer'

describe AppMap::Service::ConfigAnalyzer do
  subject { described_class.new(config_file) }

  context 'with non-existing config' do
    let(:config_file) { 'spec/fixtures/config/non_existing_config.yml' }

    example do
      expect(subject).to_not be_valid
      expect(subject.app_name).to be_nil
      expect(subject).to_not be_present
    end
  end

  context 'with valid but non rails config' do
    let(:config_file) { 'spec/fixtures/config/valid_config.yml' }

    example do
      expect(subject).to be_present
      expect(subject.app_name).to eq 'appmap'
      expect(subject.errors).to eq ['AppMap auto-configuration is currently not available for non Rails projects']
      expect(subject).to_not be_valid
    end
  end

  context 'with maximal valid config' do
    let(:config_file) { 'spec/fixtures/config/maximal_config.yml' }

    example do
      expect(subject.errors).to eq(['AppMap auto-configuration is currently not available for non Rails projects'])
    end
  end

  context 'with invalid YAML config' do
    let(:config_file) { 'spec/fixtures/config/invalid_yaml_config.yml' }

    example do
      expect(subject).to be_present
      expect(subject.app_name).to be_nil
      expect(subject).to_not be_valid
    end
  end

  context 'with incomplete config' do
    let(:config_file) { 'spec/fixtures/config/incomplete_config.yml' }

    example do
      expect(subject).to be_present
      expect(subject.app_name).to eq('app')
      expect(subject).to_not be_valid
    end
  end
end

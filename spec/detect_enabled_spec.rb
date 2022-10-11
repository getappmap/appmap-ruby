# frozen_string_literal: true

require 'spec_helper'
require 'appmap/detect_enabled'

describe AppMap::DetectEnabled do
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

  before(:each) { AppMap::DetectEnabled.clear_cache }

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

# frozen_string_literal: true

require 'spec_helper'
require 'appmap/service/integration_test_path_finder'

describe AppMap::Service::IntegrationTestPathFinder do
  subject { described_class.new('./spec/fixtures/rails6_users_app/') }

  describe '.count' do
    it 'counts existing paths' do
      expect(subject.count_paths).to be(3)
    end
  end

  describe '.find' do
    it 'finds paths' do
      expect(subject.find).to eq({
        rspec: %w[spec/controllers],
        minitest: %w[test/controllers test/integration],
        cucumber: []
      })
    end
  end
end

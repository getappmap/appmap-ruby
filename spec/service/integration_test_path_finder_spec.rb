# frozen_string_literal: true

require 'spec_helper'
require 'appmap/service/integration_test_path_finder'

describe AppMap::Service::IntegrationTestPathFinder do
  subject { described_class }

  describe '.count' do
    it 'counts existing paths' do
      expect(subject.count_paths).to be(0)
    end
  end

  describe '.find' do
    it 'finds paths' do
      expect(subject.find).to eq({ rspec: [], minitest: [], cucumber: [] })
    end
  end
end

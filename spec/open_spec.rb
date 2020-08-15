# frozen_string_literal: true

require 'spec_helper'

describe AppMap::Open do
  context 'a block of Ruby code' do
    it 'opens in the browser' do
      appmap = AppMap.record do
        File.read __FILE__
      end

      open = AppMap::Open.new(appmap)
      server = open.run_server
      page = Net::HTTP.get URI.parse("http://localhost:#{open.port}")
      expect(page).to include(%(name="data" value='{&quot;version))
      server.kill
    end
  end
end

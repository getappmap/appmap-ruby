#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class AgentSetupInitTest < Minitest::Test
  def test_status
    output = `./exe/appmap-agent-status`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = {
      :properties => {
        :config => {
          :app => 'AppMap Rubygem',
          :present => true,
          :valid => true
        },
        :project => {
          :agentVersion => AppMap::VERSION,
          :language => 'ruby',
          :remoteRecordingCapable => false,
          :integrationTests => false
        }
      }
    }.to_json
    assert_equal expected, output.strip
  end
end

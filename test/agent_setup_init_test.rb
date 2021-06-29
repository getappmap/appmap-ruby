#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class AgentSetupInitTest < Minitest::Test
  CONFIG_FILENAME = '123.yml'
  EXPECTED_CONFIG_CONTENT = %(---
name: appmap-ruby
packages:
- path: lib
)

  def test_init_when_config_exists
    output = `./exe/appmap-agent-init`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = JSON.pretty_generate({
      configuration: {
        filename: 'appmap.yml',
        contents: EXPECTED_CONFIG_CONTENT
      }
    })
    assert_equal expected, output.strip
  end

  def test_init_with_custom_config_filename
    output = `./exe/appmap-agent-init -c #{CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = JSON.pretty_generate({
      configuration: {
        filename: CONFIG_FILENAME,
        contents: EXPECTED_CONFIG_CONTENT
      }
    })
    assert_equal expected, output.strip
  end
end

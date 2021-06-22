#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class AgentSetupCLITest < Minitest::Test
  CONFIG_FILENAME = '123.yml'
  SUBFOLDER_CONFIG_FILEPATH = 'conf/123.yml'
  EXPECTED_CONFIG_CONTENT = %(name: appmap-ruby
packages:
- path: lib
)

  def test_init_when_config_exists
    output = `./exe/appmap-agent-setup init`
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_includes output, 'The AppMap config file appmap.yml already exists.'
  end

  def test_init_with_custom_config_filename
    output = `./exe/appmap-agent-setup -c #{CONFIG_FILENAME} init`
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_includes output, "The following AppMap config file #{CONFIG_FILENAME} has been created:"
    assert_equal EXPECTED_CONFIG_CONTENT, File.read(CONFIG_FILENAME)
  ensure
    File.delete(CONFIG_FILENAME) if File.exist?(CONFIG_FILENAME)
  end

  def test_init_with_custom_config_file_in_subfolder
    output = `./exe/appmap-agent-setup -c #{SUBFOLDER_CONFIG_FILEPATH} init`
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_includes output, "The following AppMap config file #{SUBFOLDER_CONFIG_FILEPATH} has been created:"
    assert_equal EXPECTED_CONFIG_CONTENT, File.read(SUBFOLDER_CONFIG_FILEPATH)
  ensure
    File.delete(SUBFOLDER_CONFIG_FILEPATH) if File.exist?(SUBFOLDER_CONFIG_FILEPATH)
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class AgentSetupValidateTest < Minitest::Test
  NON_EXISTING_CONFIG_FILENAME = '123.yml'
  INVALID_YAML_CONFIG_FILENAME = 'spec/fixtures/config/invalid_yaml_config.yml'
  INVALID_CONFIG_FILENAME = 'spec/fixtures/config/invalid_config.yml'

  def test_init_when_config_exists
    output = `./exe/appmap-agent-validate`
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_equal JSON.pretty_generate([]), output.strip
  end

  def test_init_with_non_existing_config_file
    output = `./exe/appmap-agent-validate -c #{NON_EXISTING_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = JSON.pretty_generate([
      {
        level: :error,
        filename: NON_EXISTING_CONFIG_FILENAME,
        message: 'AppMap configuration file does not exist'
      }
    ])
    assert_equal expected, output.strip
  end

  def test_init_with_invalid_YAML
    output = `./exe/appmap-agent-validate -c #{INVALID_YAML_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = JSON.pretty_generate([
      {
        level: :error,
        filename: INVALID_YAML_CONFIG_FILENAME,
        message: 'AppMap configuration is not valid YAML',
        detailed_message: "(#{INVALID_YAML_CONFIG_FILENAME}): " \
          'did not find expected key while parsing a block mapping at line 1 column 1'
      }
    ])
    assert_equal expected, output.strip
  end

  def test_init_with_invalid_data_config
    output = `./exe/appmap-agent-validate -c #{INVALID_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = JSON.pretty_generate([
      {
        level: :error,
        filename: INVALID_CONFIG_FILENAME,
        message: 'AppMap configuration could not be loaded',
        detailed_message: "undefined method `map' for \"not_array\":String\nDid you mean?  tap"
      }
    ])
    assert_equal expected, output.strip
  end
end

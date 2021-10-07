# frozen_string_literal: true

require 'test_helper'

class AgentSetupValidateTest < Minitest::Test
  NON_EXISTING_CONFIG_FILENAME = '123.yml'
  INVALID_YAML_CONFIG_FILENAME = 'spec/fixtures/config/invalid_yaml_config.yml'
  INVALID_CONFIG_FILENAME = 'spec/fixtures/config/invalid_config.yml'
  MISSING_PATH_OR_GEM_CONFIG_FILENAME = 'spec/fixtures/config/missing_path_or_gem.yml'

  def test_init_when_config_exists
    output = `./exe/appmap-agent-validate`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = JSON.pretty_generate([
      {
        level: :error,
        message: 'AppMap auto-configuration is currently not available for non Rails projects'
      }
    ])
    assert_equal expected, output.strip
  end

  def test_init_with_non_existing_config_file
    output = `./exe/appmap-agent-validate -c #{NON_EXISTING_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = JSON.pretty_generate([
      {
        level: :error,
        message: 'AppMap auto-configuration is currently not available for non Rails projects'
      },
      {
        level: :error,
        filename: NON_EXISTING_CONFIG_FILENAME,
        message: "AppMap configuration #{NON_EXISTING_CONFIG_FILENAME} file does not exist"
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
        message: 'AppMap auto-configuration is currently not available for non Rails projects'
      },
      {
        level: :error,
        filename: INVALID_YAML_CONFIG_FILENAME,
        message: "AppMap configuration #{INVALID_YAML_CONFIG_FILENAME} is not valid YAML",
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
        message: 'AppMap auto-configuration is currently not available for non Rails projects'
      },
      {
        level: :error,
        filename: INVALID_CONFIG_FILENAME,
        message: "AppMap configuration #{INVALID_CONFIG_FILENAME} could not be loaded",
        detailed_message: "no implicit conversion of String into Integer"
      }
    ])
    assert_equal expected, output.strip
  end

  def test_init_with_missing_package_key
    output = `./exe/appmap-agent-validate -c #{MISSING_PATH_OR_GEM_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = JSON.pretty_generate([
      {
        level: :error,
        message: 'AppMap auto-configuration is currently not available for non Rails projects'
      },
      {
        level: :error,
        filename: MISSING_PATH_OR_GEM_CONFIG_FILENAME,
        message: "AppMap configuration #{MISSING_PATH_OR_GEM_CONFIG_FILENAME} could not be loaded",
        detailed_message: "AppMap config 'package' element should specify 'gem' or 'path'"
      }
    ])
    assert_equal expected, output.strip
  end
end

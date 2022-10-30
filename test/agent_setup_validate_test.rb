# frozen_string_literal: true

require 'test_helper'

schema_path = File.expand_path('../../config-schema.yml', __FILE__)
CONFIG_SCHEMA = YAML.safe_load(File.read(schema_path))
class AgentSetupValidateTest < Minitest::Test
  NON_EXISTING_CONFIG_FILENAME = '123.yml'
  INVALID_YAML_CONFIG_FILENAME = 'spec/fixtures/config/invalid_yaml_config.yml'
  INVALID_CONFIG_FILENAME = 'spec/fixtures/config/invalid_config.yml'
  MISSING_PATH_OR_GEM_CONFIG_FILENAME = 'spec/fixtures/config/missing_path_or_gem.yml'

  RAILS_WARNING = {
    level: :warning,
    message: "This is not a Rails project. AppMap won't be automatically loaded.",
    detailed_message: "Please ensure you `require 'appmap'` in your test environment.",
    help_urls: [ 'https://appmap.io/docs/reference/appmap-ruby#tests-recording' ]
  }.freeze

  def check_output(output, expected_errors)
    expected = JSON.pretty_generate(
      {
        version: 2,
        errors: expected_errors,
        schema: CONFIG_SCHEMA
      }
    )
    assert_equal(expected, output.strip)
  end

  def test_init_when_config_exists
    output = `./exe/appmap-agent-validate`
    assert_equal 0, $CHILD_STATUS.exitstatus
    check_output(output, [RAILS_WARNING])
  end

  def test_init_with_non_existing_config_file
    output = `./exe/appmap-agent-validate -c #{NON_EXISTING_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    check_output(output, [
      RAILS_WARNING,
      {
        level: :error,
        filename: NON_EXISTING_CONFIG_FILENAME,
        message: "AppMap configuration #{NON_EXISTING_CONFIG_FILENAME} file does not exist"
      }
    ])
  end

  def test_init_with_invalid_YAML
    output = `./exe/appmap-agent-validate -c #{INVALID_YAML_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    check_output(output, [
      RAILS_WARNING,
      {
        level: :error,
        filename: INVALID_YAML_CONFIG_FILENAME,
        message: "AppMap configuration #{INVALID_YAML_CONFIG_FILENAME} is not valid YAML",
        detailed_message: "(#{INVALID_YAML_CONFIG_FILENAME}): " \
          'did not find expected key while parsing a block mapping at line 1 column 1'
      }
    ])
  end

  def test_init_with_invalid_data_config
    output = `./exe/appmap-agent-validate -c #{INVALID_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    check_output(output, [
      RAILS_WARNING,
      {
        level: :error,
        filename: INVALID_CONFIG_FILENAME,
        message: "AppMap configuration #{INVALID_CONFIG_FILENAME} could not be loaded",
        detailed_message: "no implicit conversion of String into Integer"
      }
    ])
  end

  def test_init_with_missing_package_key
    output = `./exe/appmap-agent-validate -c #{MISSING_PATH_OR_GEM_CONFIG_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    check_output(output, [
      RAILS_WARNING,
      {
        level: :error,
        filename: MISSING_PATH_OR_GEM_CONFIG_FILENAME,
        message: "AppMap configuration #{MISSING_PATH_OR_GEM_CONFIG_FILENAME} could not be loaded",
        detailed_message: "AppMap config 'package' element should specify 'gem' or 'path'"
      }
    ])
  end
end

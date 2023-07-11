#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class AgentSetupConfigTest < Minitest::Spec
  CONFIG_FILENAME = '123.yml'

  before do
    @exe_path = File.expand_path(File.join('..', 'exe', 'appmap-agent-config'), __dir__)
    @dir = Dir.mktmpdir('appmap-config-test')
    @cwd = Dir.pwd
    @expected_config = <<~YAML
    ---
    name: #{File.basename(@dir)}
    packages: []
    language: ruby
    appmap_dir: tmp/appmap
    YAML

    Dir.chdir(@dir)
  end

  after do
    FileUtils.rm_f(@dir)
    Dir.chdir(@cwd)
  end

  def test_config_creation
    output = `#{@exe_path}`

    assert_match(/configuration file created/, output)
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_equal(@expected_config, File.read('appmap.yml'))
  end

  def test_config_with_custom_filename
    output = `#{@exe_path} -c #{CONFIG_FILENAME}`

    assert_match(/configuration file created/, output)
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_equal(@expected_config, File.read(CONFIG_FILENAME))
  end

  def test_config_creation_with_existing_config
    File.write(CONFIG_FILENAME, 'foo')

    output = `#{@exe_path} -c #{CONFIG_FILENAME}`.strip!

    assert_match(/configuration file already exists/, output)
    assert_equal(1, $CHILD_STATUS.exitstatus)
    assert_equal('foo', File.read(CONFIG_FILENAME))
  end

  def test_config_creation_with_force_overwrites_existing_config
    File.write(CONFIG_FILENAME, 'foo')

    output = `#{@exe_path} -f`

    assert_match(/configuration file created/, output)
    assert_equal(0, $CHILD_STATUS.exitstatus)
    assert_equal(@expected_config, File.read('appmap.yml'))
  end
end

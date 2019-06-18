#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class CLITest < Minitest::Test
  OUTPUT_FILENAME = 'tmp/appmap.json'

  def setup
    FileUtils.rm_f OUTPUT_FILENAME
  end

  def test_config_file_must_exist
    output = `./exe/appmap -c foobar inspect 2>&1`

    assert_equal 1, $CHILD_STATUS.exitstatus
    assert_includes output, 'No such file or directory'
    assert_includes output, 'foobar'
  end

  def test_inspect_to_file
    `./exe/appmap inspect -o #{OUTPUT_FILENAME}`

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert File.file?(OUTPUT_FILENAME), "#{OUTPUT_FILENAME} does not exist"
  end

  def test_inspect_to_stdout
    output = `./exe/appmap inspect -o -`

    assert !File.file?(OUTPUT_FILENAME), "#{OUTPUT_FILENAME} should not exist"

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert !output.blank?, 'Output should exist in stdout'
    JSON.parse(output)
  end

  def test_record
    `./exe/appmap record -o #{OUTPUT_FILENAME} ./examples/install.rb`

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert File.file?(OUTPUT_FILENAME), "#{OUTPUT_FILENAME} does not exist"
    output = JSON.parse(File.read(OUTPUT_FILENAME))
    assert output['classMap'], 'Output should contain classMap'
    assert output['events'], 'Output should contain events'
  end

  def test_record_to_default_location
    system({ 'APPMAP_FILE' => OUTPUT_FILENAME }, './exe/appmap record ./examples/install.rb')

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert File.file?(OUTPUT_FILENAME), 'appmap.json does not exist'
  end

  def test_record_to_stdout
    `./exe/appmap record -o - ./examples/install.rb`

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert !File.file?(OUTPUT_FILENAME), "#{OUTPUT_FILENAME} should not exist"
  end

  def test_upload
    `./exe/appmap inspect -o #{OUTPUT_FILENAME}`

    scenario_uuid = `./exe/appmap upload --no-open #{OUTPUT_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    # Example: 93e1e07d-4b39-49ac-82bf-27d63e296cae
    assert_match(/^[0-9a-f]+\-[0-9a-f\-]+$/, scenario_uuid)
  end
end

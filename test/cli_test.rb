#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class CLITest < Minitest::Test
  OUTPUT_FILENAME = File.expand_path('../tmp/appmap.json', __dir__)

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
  end

  def test_inspect_fields
    output = `./exe/appmap inspect -o -`

    output = JSON.parse(output)
    assert_includes output.keys, 'version'
    assert_includes output.keys, 'classMap'
    assert_includes output.keys, 'metadata'
    assert !output.keys.include?('events')
  end

  def test_record
    output = Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} record -o #{OUTPUT_FILENAME} ./lib/cli_record_test/main.rb`.strip
    end

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert File.file?(OUTPUT_FILENAME), "#{OUTPUT_FILENAME} does not exist"
    assert_equal 'Hello', output
    output = JSON.parse(File.read(OUTPUT_FILENAME))
    assert output['classMap'], 'Output should contain classMap'
    assert output['events'], 'Output should contain events'
  end

  def test_record_to_default_location
    Dir.chdir 'test/fixtures/cli_record_test' do
      system({ 'APPMAP_FILE' => OUTPUT_FILENAME }, "#{File.expand_path '../exe/appmap', __dir__} record ./lib/cli_record_test/main.rb")
    end

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert File.file?(OUTPUT_FILENAME), 'appmap.json does not exist'
  end

  def test_record_to_stdout
    output = Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} record -o - ./lib/cli_record_test/main.rb`
    end

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_includes output, %("location":"lib/cli_record_test")
    assert !File.file?(OUTPUT_FILENAME), "#{OUTPUT_FILENAME} should not exist"
  end

  def test_upload
    `./exe/appmap inspect -o #{OUTPUT_FILENAME}`

    upload_output = `./exe/appmap upload --no-open #{OUTPUT_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    # Example: 93e1e07d-4b39-49ac-82bf-27d63e296cae
    assert_match(/Scenario Id/, upload_output)
    assert_match(/Batch Id/, upload_output)
    assert_match(/[0-9a-f]+\-[0-9a-f\-]+/, upload_output)
  end
end

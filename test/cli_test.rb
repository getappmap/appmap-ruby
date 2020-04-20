#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class CLITest < Minitest::Test
  OUTPUT_FILENAME = File.expand_path('../tmp/appmap.json', __dir__)
  STATS_OUTPUT_FILENAME = File.expand_path('../tmp/stats.txt', __dir__)

  def setup
    FileUtils.rm_f OUTPUT_FILENAME
    FileUtils.rm_f STATS_OUTPUT_FILENAME
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

  def test_stats_to_file
    Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} record -o #{OUTPUT_FILENAME} ./lib/cli_record_test/main.rb`.strip
    end
    assert_equal 0, $CHILD_STATUS.exitstatus

    output = Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} stats -o #{STATS_OUTPUT_FILENAME} #{OUTPUT_FILENAME}`.strip
    end
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_equal '', output
    assert File.file?(OUTPUT_FILENAME), "#{OUTPUT_FILENAME} does not exist"
  end


  def test_stats_text
    Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} record -o #{OUTPUT_FILENAME} ./lib/cli_record_test/main.rb`.strip
    end
    assert_equal 0, $CHILD_STATUS.exitstatus

    output = Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} stats -o - #{OUTPUT_FILENAME}`.strip
    end

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_equal <<~OUTPUT.strip, output.strip
    Class frequency:
    ----------------
    2	Main

    Method frequency:
    ----------------
    2	Main.say_hello
    OUTPUT
  end

  def test_stats_json
    Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} record -o #{OUTPUT_FILENAME} ./lib/cli_record_test/main.rb`.strip
    end
    assert_equal 0, $CHILD_STATUS.exitstatus

    output = Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} stats -f json -o - #{OUTPUT_FILENAME}`.strip
    end

    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_equal <<~OUTPUT.strip, output.strip
    {
      "class_frequency": [
        {
          "name": "Main",
          "count": 2
        }
      ],
      "method_frequency": [
        {
          "name": "Main.say_hello",
          "count": 2
        }
      ]
    }
    OUTPUT
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
    # Event path
    assert_includes output, %("path":"lib/cli_record_test/main.rb")
    # Function location
    assert_includes output, %("location":"lib/cli_record_test/main.rb:3")
    assert !File.file?(OUTPUT_FILENAME), "#{OUTPUT_FILENAME} should not exist"
  end

  def test_upload
    Dir.chdir 'test/fixtures/cli_record_test' do
      `#{File.expand_path '../exe/appmap', __dir__} record -o #{OUTPUT_FILENAME} ./lib/cli_record_test/main.rb`
    end

    upload_output = `./exe/appmap upload --org default --user admin --no-open #{OUTPUT_FILENAME}`
    assert_equal 0, $CHILD_STATUS.exitstatus
    # Example: 93e1e07d-4b39-49ac-82bf-27d63e296cae
    assert_match(/Scenario Id/, upload_output)
    assert_match(/Batch Id/, upload_output)
    assert_match(/[0-9a-f]+\-[0-9a-f\-]+/, upload_output)
  end
end

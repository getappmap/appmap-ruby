#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class CLITest < Minitest::Test
  def test_init
    output = `./exe/appmap init`
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_equal 'Initializing .appmap.yml...', output
  end

  def test_init_with_custom_config_file
    output = `./exe/appmap -c 123.yml init`
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_equal 'Initializing 123.yml...', output
  end
end
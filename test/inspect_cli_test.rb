#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class InspectCLITest < Minitest::Test
  def test_help
    output = `./exe/appmap-inspect --help`
    assert_equal 0, $CHILD_STATUS.exitstatus
    assert_includes output, 'Search AppMaps for references to a code object'
  end
end

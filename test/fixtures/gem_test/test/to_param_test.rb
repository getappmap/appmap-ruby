#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appmap/minitest'
require 'minitest/autorun'
require 'active_support'
require 'active_support/core_ext'

class ToParamTest < ::Minitest::Test
  def test_to_param
    # record use of a core extension
    assert_equal 'my+id', 'my+id'.to_param
  end
end

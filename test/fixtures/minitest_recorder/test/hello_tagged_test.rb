#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

require 'minitest/autorun'
require 'appmap/minitest'
require 'hello'

class HelloTaggedTest < ::Minitest::Test
  tag :noappmap
  def test_tagged
    assert_equal 'Hello!', Hello.new.say_hello
  end

  def test_untagged
    assert_equal 'Hello!', Hello.new.say_hello
  end
end

#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'appmap/minitest'
require 'hello'

class HelloTest < ::Minitest::Test
  def test_hello
    assert_equal 'Hello!', Hello.new.say_hello
  end
end

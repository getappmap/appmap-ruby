#!/usr/bin/env ruby
# frozen_string_literal: true

require 'minitest/autorun'
require 'appmap/minitest'
require 'hello'

class HelloFailedTest < ::Minitest::Test
  def test_failed
    assert_equal 'Bye!', Hello.new.say_hello
  end
end

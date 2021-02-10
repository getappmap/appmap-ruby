#!/usr/bin/env ruby
# frozen_string_literal: true

require 'appmap/minitest'
require 'minitest/autorun'
require 'parser/current'

class ParserTest < ::Minitest::Test
  def test_parser
    Parser::CurrentRuby.parse(File.read(__FILE__))
  end
end

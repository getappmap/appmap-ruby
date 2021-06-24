#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'
require 'json'

class GemTest < Minitest::Test
  def perform_gem_test(test_name)
    Bundler.with_clean_env do
      Dir.chdir 'test/fixtures/gem_test' do
        FileUtils.rm_rf 'tmp'
        system 'bundle config --local local.appmap ../../..'
        system 'bundle'
        system({ 'APPMAP' => 'true' }, %(bundle exec ruby -Ilib -Itest test/#{test_name}_test.rb))

        yield
      end
    end
  end

  def test_record_gem
    perform_gem_test 'parser' do
      appmap_file = 'tmp/appmap/minitest/Parser_parser.appmap.json'
      appmap = JSON.parse(File.read(appmap_file))
      events = appmap['events']
      assert_equal 2, events.size
      assert_equal 'call', events.first['event']
      assert_equal 'default_parser', events.first['method_id']
      assert_match /\lib\/parser\/base\.rb$/, events.first['path']
      assert_equal 'return', events.second['event']
      assert_equal 1, events.second['parent_id']
    end
  end
end

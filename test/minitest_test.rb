#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class MinitestTest < Minitest::Test
  def perform_minitest_test(test_name)
    Bundler.with_clean_env do
      Dir.chdir 'test/fixtures/minitest_recorder' do
        FileUtils.rm_rf 'tmp'
        system 'bundle config --local local.appmap ../../..'
        system 'bundle'
        system({ 'APPMAP' => 'true' }, %(bundle exec ruby -Ilib -Itest test/#{test_name}_test.rb))

        yield
      end
    end
  end

  def test_hello
    perform_minitest_test 'hello' do
      appmap_file = 'tmp/appmap/minitest/Hello_hello.appmap.json'

      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']
      assert_equal 'minitest_recorder', metadata['app']
      assert_equal 'minitest', metadata['recorder']['name']
      assert_equal 'ruby', metadata['language']['name']
      assert_equal 'Hello hello', metadata['name']
      assert_equal 'test/hello_test.rb:9', metadata['source_location']
    end
  end
end

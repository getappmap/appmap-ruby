#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class MockCompatibilityTest < Minitest::Test
  def perform_minitest_test(test_name, env = {})
    Bundler.with_clean_env do
      Dir.chdir 'test/fixtures/mocha_mock_app' do
        FileUtils.rm_rf 'tmp'
        system 'bundle config --local local.appmap ../../..'
        system 'bundle'
        system(env.merge({ 'APPMAP' => 'true' }), %(bundle exec ruby -Ilib -Itest test/#{test_name}_test.rb))

        yield
      end
    end
  end

  def test_expectation
    perform_minitest_test('sheep') do
      appmap_file = 'tmp/appmap/minitest/Sheep_sheep.appmap.json'

      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']
      assert_equal 'succeeded', metadata['test_status']
    end
  end

  def test_expectation_without_autorequire
    perform_minitest_test('sheep', 'APPMAP_AUTOREQUIRE' => 'false') do
      appmap_file = 'tmp/appmap/minitest/Sheep_sheep.appmap.json'

      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']
      assert_equal 'succeeded', metadata['test_status']
    end
  end
end

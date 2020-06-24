#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class CucumberTest < Minitest::Test
  def perform_test(dir)
    Bundler.with_clean_env do
      Dir.chdir "test/fixtures/#{dir}" do
        FileUtils.rm_rf 'tmp'
        system 'bundle config --local local.appmap ../../..'
        system 'bundle'
        system({ 'APPMAP' => 'true' }, %(bundle exec cucumber))

        yield
      end
    end
  end

  def test_cucumber
    perform_test 'cucumber_recorder' do
      appmap_file = 'tmp/appmap/cucumber/Say_hello.appmap.json'

      assert File.file?(appmap_file),
             %(appmap output file does not exist in #{Dir.new('tmp/appmap/cucumber').entries.join(', ')})
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']

      assert_equal 'say_hello', metadata['feature_group']
      assert_equal 'I can say hello', metadata['feature']
      assert_equal 'Say hello', metadata['name']
      assert_includes metadata.keys, 'client'
      assert_equal({ name: 'appmap', url: AppMap::URL, version: AppMap::VERSION }.stringify_keys, metadata['client'])
      assert_includes metadata.keys, 'recorder'
      assert_equal({ name: 'cucumber' }.stringify_keys, metadata['recorder'])

      assert_includes metadata.keys, 'frameworks'
      cucumber = metadata['frameworks'].select {|f| f['name'] == 'cucumber'}
      assert_equal 1, cucumber.count
    end
  end

  def test_cucumber4
    perform_test 'cucumber4_recorder' do
      appmap_file = 'tmp/appmap/cucumber/Say_hello.appmap.json'

      assert File.file?(appmap_file),
             %(appmap output file does not exist in #{Dir.new('tmp/appmap/cucumber').entries.join(', ')})
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']

      assert_equal 'say_hello', metadata['feature_group']
      # In cucumber4, there's no access to the feature name from within the executing scenario
      # (as far as I can tell).
      assert_equal 'Say hello', metadata['feature']
      assert_equal 'Say hello', metadata['name']
      assert_includes metadata.keys, 'client'
      assert_equal({ name: 'appmap', url: AppMap::URL, version: AppMap::VERSION }.stringify_keys, metadata['client'])
      assert_includes metadata.keys, 'recorder'
      assert_equal({ name: 'cucumber' }.stringify_keys, metadata['recorder'])

      assert_includes metadata.keys, 'frameworks'
      cucumber = metadata['frameworks'].select {|f| f['name'] == 'cucumber'}
      assert_equal 1, cucumber.count
    end
  end
end

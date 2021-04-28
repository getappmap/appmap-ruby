#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class RSpecTest < Minitest::Test
  def perform_test(test_name)
    Bundler.with_clean_env do
      Dir.chdir 'test/fixtures/rspec_recorder' do
        FileUtils.rm_rf 'tmp'
        system 'bundle config --local local.appmap ../../..'
        system 'bundle'
        system({ 'APPMAP' => 'true' }, %(bundle exec rspec spec/#{test_name}.rb))

        yield
      end
    end
  end

  def test_record_decorated_rspec
    perform_test 'decorated_hello_spec' do
      appmap_file = 'tmp/appmap/rspec/Hello_says_hello.appmap.json'

      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']
      assert_equal 'Hello says hello', metadata['name']
      assert_equal 'spec/decorated_hello_spec.rb', metadata['source_location']
      assert_includes metadata.keys, 'client'
      assert_equal({ name: 'appmap', url: AppMap::URL, version: AppMap::VERSION }.stringify_keys, metadata['client'])
      assert_includes metadata.keys, 'recorder'
      assert_equal({ name: 'rspec' }.stringify_keys, metadata['recorder'])

      assert_includes metadata.keys, 'frameworks'
      rspec = metadata['frameworks'].select {|f| f['name'] == 'rspec'}
      assert_equal 1, rspec.count
    end
  end

  def test_record_plain_rspec
    perform_test 'plain_hello_spec' do
      appmap_file = 'tmp/appmap/rspec/Hello_says_hello.appmap.json'
      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']
      assert_equal 'Hello says hello', metadata['name']
    end
  end

  def test_record_labeled_rspec
    perform_test 'labeled_hello_spec' do
      appmap_file = 'tmp/appmap/rspec/Hello_says_hello.appmap.json'
      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']
    end
  end
end

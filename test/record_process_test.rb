#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class RecordProcessTest < Minitest::Test
  def perform_test(program_name)
    Bundler.with_clean_env do
      Dir.chdir 'test/fixtures/record_process' do
        FileUtils.rm_rf 'tmp'
        system 'bundle config --local local.appmap ../../..'
        system 'bundle'
        system(%(bundle exec ruby #{program_name}))

        yield
      end
    end
  end

  def test_hello
    perform_test 'hello.rb' do
      appmap_file = 'appmap.json'

      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_includes appmap.keys, 'metadata'
      metadata = appmap['metadata']
      assert_equal 'record_process', metadata['app']
      assert_equal 'record_process', metadata['recorder']['name']
      assert_equal 'ruby', metadata['language']['name']
    end
  end
end

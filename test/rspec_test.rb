#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class RSpecTest < Minitest::Test
  def test_record_rspec
    Bundler.with_clean_env do
      Dir.chdir 'test/fixtures/rspec_recorder' do
        appmap_file = 'tmp/appmap/rspec/Hello says hello.json'
        FileUtils.rm_rf 'tmp'
        system 'bundle'
        system({ 'APPMAP' => 'true' }, 'bundle exec rspec')
        assert File.file?(appmap_file), 'appmap output file does not exist'
        assert_includes File.read(appmap_file), %("class":"String","value":"Hello!")
        assert_includes File.read(appmap_file), %("feature":"Say hello")
        assert_includes File.read(appmap_file), %("feature_group":"Hello")
      end
    end
  end
end

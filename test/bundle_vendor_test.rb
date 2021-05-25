#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class BundleVendorTest < Minitest::Test
  def perform_bundle_vendor_app(test_name)
    Bundler.with_clean_env do
      Dir.chdir 'test/fixtures/bundle_vendor_app' do
        FileUtils.rm_rf 'tmp'
        FileUtils.mkdir_p 'tmp'
        system 'bundle config --local local.appmap ../../..'
        system 'bundle'
        system(%(bundle exec ruby -Ilib -Itest cli.rb add foobar))
        system({ 'APPMAP' => 'true' }, %(bundle exec ruby -Ilib -Itest cli.rb list))

        yield
      end
    end
  end

  def test_record_gem
    perform_bundle_vendor_app 'parser' do
      appmap_file = 'tmp/bundle_vendor_app.appmap.json'
      appmap = JSON.parse(File.read(appmap_file))
      assert appmap['classMap'].find { |co| co['name'] == 'gli' }
      assert appmap['events'].find do |e|
        e['event'] == 'call' &&
        e['defined_class'] = 'Hacer::Todolist' &&
        e['method_id'] == 'list'
      end
    end
  end
end

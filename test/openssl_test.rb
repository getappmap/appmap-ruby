#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'
require 'English'

class OpenSSLTest < Minitest::Test
  def perform_test(test_name)
    Bundler.with_clean_env do
      Dir.chdir 'test/fixtures/openssl_recorder' do
        FileUtils.rm_rf 'tmp'
        system 'bundle config --local local.appmap ../../..'
        system 'bundle'
        system({ 'APPMAP' => 'true' }, %(bundle exec ruby lib/openssl_#{test_name}.rb))

        yield
      end
    end
  end

  def expectation(name)
    File.read File.join __dir__, 'expectations', name
  end

  def test_key_sign
    perform_test 'key_sign' do
      appmap_file = 'appmap.json'

      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_equal [ { 'recorder' => 'lib/openssl_key_sign.rb' } ], appmap['metadata']
      assert_equal JSON.parse(expectation('openssl_test_key_sign1.json')), appmap['classMap']
      sanitized_events = appmap['events'].map(&:deep_symbolize_keys).map(&AppMap::Util.method(:sanitize_event)).map do |event|
        delete_value = ->(obj) { (obj || {}).delete(:value) }
        delete_value.call(event[:receiver])
        delete_value.call(event[:return_value])
        event
      end

      diff = Diffy::Diff.new(
        expectation('openssl_test_key_sign2.json').strip,
        JSON.pretty_generate(sanitized_events).strip
      )
      assert_equal '', diff.to_s
    end
  end
end

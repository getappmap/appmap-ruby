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
        system({ 'APPMAP' => 'true', 'DEBUG' => 'true' }, %(bundle exec ruby lib/openssl_#{test_name}.rb))

        yield
      end
    end
  end

  def test_key_sign
    perform_test 'key_sign' do
      appmap_file = 'appmap.json'

      assert File.file?(appmap_file), 'appmap output file does not exist'
      appmap = JSON.parse(File.read(appmap_file))
      assert_equal AppMap::APPMAP_FORMAT_VERSION, appmap['version']
      assert_equal [ { 'recorder' => 'lib/openssl_key_sign.rb' } ], appmap['metadata']
      assert_equal JSON.parse(<<~JSON), appmap['classMap']
      [
        {
          "name": "lib",
          "type": "package",
          "children": [
            {
              "name": "Example",
              "type": "class",
              "children": [
                {
                  "name": "sign",
                  "type": "function",
                  "location": "lib/openssl_key_sign.rb:10",
                  "static": true
                }
              ]
            }
          ]
        },
        {
          "name": "openssl",
          "type": "package",
          "children": [
            {
              "name": "OpenSSL",
              "type": "class",
              "children": [
                {
                  "name": "PKey",
                  "type": "class",
                  "children": [
                    {
                      "name": "PKey",
                      "type": "class",
                      "children": [
                        {
                          "name": "sign",
                          "type": "function",
                          "location": "OpenSSL::PKey::PKey#sign",
                          "static": false,
                          "labels": [
                            "security"
                          ]
                        }
                      ]
                    }
                  ]
                }
              ]
            }
          ]
        },
        {
          "name": "io",
          "type": "package",
          "children": [
            {
              "name": "IO",
              "type": "class",
              "children": [
                {
                  "name": "write",
                  "type": "function",
                  "location": "IO#write",
                  "static": false,
                  "labels": [
                    "io"
                  ]
                }
              ]
            }
          ]
        }
      ]
      JSON
      sanitized_events = appmap['events'].map(&:deep_symbolize_keys).map(&AppMap::Util.method(:sanitize_event)).map do |event|
        delete_value = ->(obj) { (obj || {}).delete(:value) }
        delete_value.call(event[:receiver])
        delete_value.call(event[:return_value])
        event
      end

      diff = Diffy::Diff.new(<<~JSON.strip, JSON.pretty_generate(sanitized_events).strip)
      [
        {
          "id": 1,
          "event": "call",
          "defined_class": "Example",
          "method_id": "sign",
          "path": "lib/openssl_key_sign.rb",
          "lineno": 10,
          "static": true,
          "parameters": [
      
          ],
          "receiver": {
            "class": "Module"
          }
        },
        {
          "id": 2,
          "event": "call",
          "defined_class": "OpenSSL::PKey::PKey",
          "method_id": "sign",
          "path": "OpenSSL::PKey::PKey#sign",
          "static": false,
          "parameters": [
            {
              "name": "arg",
              "class": "OpenSSL::Digest::SHA256",
              "value": "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855",
              "kind": "req"
            },
            {
              "name": "arg",
              "class": "String",
              "value": "the document",
              "kind": "req"
            }
          ],
          "receiver": {
            "class": "OpenSSL::PKey::RSA"
          }
        },
        {
          "id": 3,
          "event": "return",
          "parent_id": 2,
          "return_value": {
            "class": "String"
          }
        },
        {
          "id": 4,
          "event": "return",
          "parent_id": 1,
          "return_value": {
            "class": "String"
          }
        },
        {
          "id": 5,
          "event": "call",
          "defined_class": "IO",
          "method_id": "write",
          "path": "IO#write",
          "static": false,
          "parameters": [
            {
              "name": "arg",
              "class": "String",
              "value": "Computed signature",
              "kind": "rest"
            }
          ],
          "receiver": {
            "class": "IO"
          }
        },
        {
          "id": 6,
          "event": "return",
          "parent_id": 5,
          "return_value": {
            "class": "Integer"
          }
        }
      ]
      JSON
      assert_equal '', diff.to_s
    end
  end
end

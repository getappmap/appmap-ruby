# frozen_string_literal: true

require 'rails_spec_helper'
require 'appmap/config'

describe AppMap::Config, docker: false do
  it 'loads as expected' do
    config_data = {
      name: 'test',
      packages: [],
      functions: [
        {
          name: 'pkg/cls#fn',
        },
        {
          methods: ['cls#new_fn'],
          path: 'pkg'
        }
      ]
    }.deep_stringify_keys!
    config = AppMap::Config.load(config_data)

    expect(JSON.parse(JSON.generate(config.as_json))).to eq(JSON.parse(<<~FIXTURE))
    {
      "name": "test",
      "appmap_dir": "tmp/appmap",
      "packages": [
      ],
      "swagger_config": {
        "project_name": null,
        "project_version": "1.0",
        "output_dir": "swagger",
        "description": "Generate Swagger from AppMaps"
      },
      "depends_config": {
        "base_dir": null,
        "base_branches": [
          "remotes/origin/main",
          "remotes/origin/master"
        ],
        "test_file_patterns": [
          "spec/**/*_spec.rb",
          "test/**/*_test.rb"
        ],
        "dependent_tasks": [
          "swagger"
        ],
        "description": "Bring AppMaps up to date with local file modifications, and updated derived data such as Swagger files",
        "rspec_environment_method": "AppMap::Depends.test_env",
        "minitest_environment_method": "AppMap::Depends.test_env",
        "rspec_select_tests_method": "AppMap::Depends.select_rspec_tests",
        "minitest_select_tests_method": "AppMap::Depends.select_minitest_tests",
        "rspec_test_command_method": "AppMap::Depends.rspec_test_command",
        "minitest_test_command_method": "AppMap::Depends.minitest_test_command"
      },
      "hook_paths": [
        "pkg",
        "#{Gem.loaded_specs['activesupport'].gem_dir}"
      ],
      "exclude": [
      ],
      "functions": [
        {
          "cls": "cls",
          "target_methods": {
            "package": "pkg",
            "method_names": [
              "fn"
            ]
          }
        },
        {
          "cls": "cls",
          "target_methods": {
            "package": "pkg",
            "method_names": [
              "new_fn"
            ]
          }
        }
      ],
      "builtin_hooks": {
        "JSON::Ext::Parser": [
          {
            "package": "json",
            "method_names": [
              "parse"
            ]
          }
        ],
        "JSON::Ext::Generator::State": [
          {
            "package": "json",
            "method_names": [
              "generate"
            ]
          }
        ],
        "Net::HTTP": [
          {
            "package": "net/http",
            "method_names": [
              "request"
            ]
          }
        ],
        "OpenSSL::PKey::PKey": [
          {
            "package": "openssl",
            "method_names": [
              "sign"
            ]
          }
        ],
        "OpenSSL::X509::Request": [
          {
            "package": "openssl",
            "method_names": [
              "sign"
            ]
          },
          {
            "package": "openssl",
            "method_names": [
              "verify"
            ]
          }
        ],
        "OpenSSL::X509::Certificate": [
          {
            "package": "openssl",
            "method_names": [
              "sign"
            ]
          }
        ],
        "OpenSSL::PKCS5": [
          {
            "package": "openssl",
            "method_names": [
              "pbkdf2_hmac"
            ]
          },
          {
            "package": "openssl",
            "method_names": [
              "pbkdf2_hmac_sha1"
            ]
          }
        ],
        "OpenSSL::Cipher": [
          {
            "package": "openssl",
            "method_names": [
              "encrypt"
            ]
          },
          {
            "package": "openssl",
            "method_names": [
              "decrypt"
            ]
          }
        ],
        "Psych": [
          {
            "package": "yaml",
            "method_names": [
              "load"
            ]
          },
          {
            "package": "yaml",
            "method_names": [
              "load_stream"
            ]
          },
          {
            "package": "yaml",
            "method_names": [
              "parse"
            ]
          },
          {
            "package": "yaml",
            "method_names": [
              "parse_stream"
            ]
          },
          {
            "package": "yaml",
            "method_names": [
              "dump"
            ]
          },
          {
            "package": "yaml",
            "method_names": [
              "dump_stream"
            ]
          }
        ]
      },
      "gem_hooks": {
        "cls": [
          {
            "package": "pkg",
            "method_names": [
              "fn"
            ]
          },
          {
            "package": "pkg",
            "method_names": [
              "new_fn"
            ]
          }
        ],
        "ActiveSupport::Callbacks::CallbackSequence": [
          {
            "package": "activesupport",
            "method_names": [
              "invoke_before"
            ]
          },
          {
            "package": "activesupport",
            "method_names": [
              "invoke_after"
            ]
          }
        ],
        "ActiveSupport::SecurityUtils": [
          {
            "package": "activesupport",
            "method_names": [
              "secure_compare"
            ]
          }
        ]
      }
    }
    FIXTURE
  end

  context do
    let(:warnings) { @warnings ||= [] }
    let(:warning) { warnings.join }
    before do
      expect(AppMap::Config).to receive(:warn).at_least(1) { |msg| warnings << msg }
    end
    it 'prints a warning and uses a default config' do
      config = AppMap::Config.load_from_file 'no/such/file'
      expect(config.to_h).to eq(YAML.load(<<~CONFIG))
      :name: appmap-ruby
      :packages:
      - :name: lib
        :path: lib
        :handler_class: AppMap::Handler::Function
        :shallow: false
      :functions: []
      :exclude: []
      CONFIG
      expect(warning).to include('NOTICE: The AppMap config file no/such/file was not found!')
    end
  end
end

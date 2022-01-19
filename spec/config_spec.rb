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

    expect(config.as_json.keys.sort).to eq(["appmap_dir", "builtin_hooks", "depends_config", "exclude", "functions", "gem_hooks", "hook_paths", "name", "packages", "swagger_config"])
    expect(config.as_json['appmap_dir']).to eq('tmp/appmap')
    expect(config.as_json['name']).to eq('test')
    expect(config.as_json['packages']).to eq([])
    expect(config.as_json['depends_config']).to eq({
      "base_dir" => nil,
      "base_branches" => [
        "remotes/origin/main",
        "remotes/origin/master"
      ],
      "test_file_patterns" => [
        "spec/**/*_spec.rb",
        "test/**/*_test.rb"
      ],
      "dependent_tasks" => [
        "swagger"
      ],
      "description" => "Bring AppMaps up to date with local file modifications, and updated derived data such as Swagger files",
      "rspec_environment_method" => "AppMap::Depends.test_env",
      "minitest_environment_method" => "AppMap::Depends.test_env",
      "rspec_select_tests_method" => "AppMap::Depends.select_rspec_tests",
      "minitest_select_tests_method" => "AppMap::Depends.select_minitest_tests",
      "rspec_test_command_method" => "AppMap::Depends.rspec_test_command",
      "minitest_test_command_method" => "AppMap::Depends.minitest_test_command"
    })
    expect(config.as_json['swagger_config']).to eq({
      "project_name" => nil,
      "project_version" => "1.0",
      "output_dir" => "swagger",
      "description" => "Generate Swagger from AppMaps"
    })
    expect(config.as_json['hook_paths']).to eq([
      "pkg",
      "#{Gem.loaded_specs['activesupport'].gem_dir}"
    ])
    expect(config.as_json['exclude']).to eq([])
    expect(config.as_json['functions'].map(&:deep_stringify_keys)).to eq([
      {
        "cls" => "cls",
        "target_methods" => {
          "package" => "pkg",
          "method_names" => [
            :fn
          ]
        }
      },
      {
        "cls" => "cls",
        "target_methods" => {
          "package" => "pkg",
          "method_names" => [
            :new_fn
          ]
        }
      }
    ])
    expect(config.as_json['builtin_hooks']).to have_key('JSON::Ext::Parser')
    expect(config.as_json['builtin_hooks']['JSON::Ext::Parser'].map(&:deep_stringify_keys)).to eq([{
        "package" => "json",
        "method_names" => [
          :parse
        ]
      }
    ])
    expect(config.as_json['gem_hooks']).to have_key('cls')
    expect(config.as_json['gem_hooks']['cls'].map(&:deep_stringify_keys)).to eq([
      {
        "package" => "pkg",
        "method_names" => [
          :fn
        ]
      },
      {
        "package" => "pkg",
        "method_names" => [
          :new_fn
        ]
      }
    ])
    expect(config.as_json['gem_hooks']).to have_key('ActiveSupport::Callbacks::CallbackSequence')
    expect(config.as_json['gem_hooks']['ActiveSupport::Callbacks::CallbackSequence'].map(&:deep_stringify_keys)).to eq([
      {
        "package" => "activesupport",
        "method_names" => [
          :invoke_before
        ]
      },
      {
        "package" => "activesupport",
        "method_names" => [
          :invoke_after
        ]
      }
    ])
  end

  describe AppMap::Config::Package do
    describe :build_from_gem do
      let(:mock_rails) { double(logger: double(info: true)) }

      before do
        stub_const('Rails', mock_rails)
      end

      it 'does not return a truthy value on failure' do
        result = AppMap::Config::Package.build_from_gem('some_missing_gem_name', optional: true)
        expect(result).to_not be_truthy
      end
    end
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

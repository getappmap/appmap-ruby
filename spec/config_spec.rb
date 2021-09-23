# frozen_string_literal: true

require 'rails_spec_helper'
require 'appmap/config'

describe AppMap::Config, docker: false do
  it 'loads from a Hash' do
    config_data = {
      exclude: [],
      name: 'test',
      packages: [
        {
          path: 'path-1'
        },
        {
          path: 'path-2',
          exclude: [ 'exclude-1' ]
        }
      ],
      functions: [
        {
          package: 'pkg',
          class: 'cls',
          function: 'fn',
          label: 'lbl'
        }
      ]
    }.deep_stringify_keys!
    config = AppMap::Config.load(config_data)

    config_expectation = {
      exclude: [],
      name: 'test',
      packages: [
        {
          path: 'path-1',
          handler_class: 'AppMap::Handler::Function'
        },
        {
          path: 'path-2',
          handler_class: 'AppMap::Handler::Function',
          exclude: [ 'exclude-1' ]
        }
      ],
      functions: [
        {
          package: 'pkg',
          class: 'cls',
          functions: [ :fn ],
          labels: ['lbl']
        }
      ]
    }.deep_stringify_keys!

    expect(config.to_h.deep_stringify_keys!).to eq(config_expectation)
  end

  it 'interprets a function in canonical name format' do
    config_data = {
      name: 'test',
      packages: [],
      functions: [
        {
          name: 'pkg/cls#fn',
        }
      ]
    }.deep_stringify_keys!
    config = AppMap::Config.load(config_data)

    config_expectation = {
      exclude: [],
      name: 'test',
      packages: [],
      functions: [
        {
          package: 'pkg',
          class: 'cls',
          functions: [ :fn ],
        }
      ]
    }.deep_stringify_keys!

    expect(config.to_h.deep_stringify_keys!).to eq(config_expectation)
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
      - :path: lib
        :handler_class: AppMap::Handler::Function
        :shallow: false
      :functions: []
      :exclude: []
      CONFIG
      expect(warning).to include('NOTICE: The AppMap config file no/such/file was not found!')
    end
  end
end

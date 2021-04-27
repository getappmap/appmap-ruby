# frozen_string_literal: true

require 'rails_spec_helper'
require 'active_support/core_ext'
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
end

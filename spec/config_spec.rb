# frozen_string_literal: true

require 'rails_spec_helper'
require 'active_support/core_ext'
require 'appmap/config'

describe AppMap::Config, docker: false do
  it 'loads from a Hash' do
    config_data = {
      name: 'test',
      packages: [
        {
          path: 'path-1'
        },
        {
          path: 'path-2',
          exclude: [ 'exclude-1' ]
        }
      ]
    }.deep_stringify_keys!
    config = AppMap::Config.load(config_data)

    expect(config.to_h.deep_stringify_keys!).to eq(config_data)
  end
end

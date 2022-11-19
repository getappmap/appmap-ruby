# frozen_string_literal: true

require 'spec_helper'
require_relative '../lib/appmap/value_inspector'

describe 'Schema example' do
  let(:parent_id) { nil }
  let(:exception) { nil }
  let(:max_depth) { nil }
  let(:schema) {
    options = {}
    options[:max_depth] = max_depth if max_depth
    AppMap::ValueInspector.detect_schema value, **options
  }
  
  describe 'Hash value' do
    let(:value) { { id: 1, contents: 'some text' } }
    it 'is a one level schema' do
      expect(schema).to match(hash_including(
        properties: [ 
          { name: :id, class: 'Integer' },
          { name: :contents, class: 'String' }
        ]
      ))
    end
  end

  describe 'nested Hash value' do
    let(:value) { { page: { page_number: 1, page_size: 20, total: 2383 } } }
    it 'is a two level schema' do
      expect(schema).to match(hash_including(
          properties: [
            {
              name: :page,
              class: 'Hash',
              properties: [ 
                { name: :page_number, class: 'Integer' },
                { name: :page_size, class: 'Integer' },
                { name: :total, class: 'Integer' }
              ]
            }
          ]
        ))
    end
    describe 'max depth' do
      let(:max_depth) { 1 }
      it 'respects max depth' do
        expect(schema).to match(hash_including(
            properties: [
              {
                name: :page,
                class: 'Hash'
              }
            ]
          ))
      end
    end
  end

  describe 'Array of Hashes' do
    let(:value) { [ { id: 1, contents: 'some text' }, { id: 2 } ] }
    it 'is an array containing the schema' do
      expect(schema).to match(hash_including(
          properties: [ 
            { name: :id, class: 'Integer' },
            { name: :contents, class: 'String' }
          ]
        ))
    end
  end
end

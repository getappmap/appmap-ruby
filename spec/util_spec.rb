# frozen_string_literal: true

require 'spec_helper'
require 'appmap/util'

describe AppMap::Util, docker: false do
  describe 'scenario_filename' do
    let(:subject) { AppMap::Util.method(:scenario_filename) }
    it 'leaves short names alone' do
      expect(subject.call('foobar')).to eq('foobar.appmap.json')
    end
    it 'has a customizable suffix' do
      expect(subject.call('foobar', extension: '.json')).to eq('foobar.json')
    end
    it 'limits the filename length' do
      fname = (0...104).map { |i| ((i % 26) + 97).chr }.join

      expect(subject.call(fname, max_length: 50)).to eq('abcdefghijklmno-RAd_SFbH1sUZ_OXfwPsfzw.appmap.json')
    end
  end
  describe 'swaggerize path' do
    it 'replaces rails-style parameters' do
      expect(AppMap::Util.swaggerize_path('/org/:org_id(.:format)')).to eq('/org/{org_id}')
    end

    it 'strips the format specifier' do
      expect(AppMap::Util.swaggerize_path('/org(.:format)')).to eq('/org')
    end

    it 'ignores malformed parameter specs' do
      expect(AppMap::Util.swaggerize_path('/org/o:rg_id')).to eq('/org/o:rg_id')
    end

    it 'ignores already swaggerized paths' do
      expect(AppMap::Util.swaggerize_path('/org/{org_id}')).to eq('/org/{org_id}')
    end
  end
end

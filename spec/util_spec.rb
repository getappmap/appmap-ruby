# frozen_string_literal: true

require 'spec_helper'
require 'appmap/util'

describe AppMap::Util do
  let(:subject) { AppMap::Util.method(:scenario_filename) }
  describe 'scenario_filename' do
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
end

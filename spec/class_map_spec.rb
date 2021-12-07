# frozen_string_literal: true

require 'spec_helper'

describe 'AppMap::ClassMap' do
  describe '.build_from_methods' do
    it 'includes method comment' do
      map = AppMap.class_map([ruby_method((method :test_method))])
      function = dig_map(map, 5)[0]
      expect(function).to include(:comment)
    end

    # test method comment
    def test_method
      'test method body'
    end

    def ruby_method(method)
      AppMap::Trace::RubyMethod.new AppMap::Config::Package.new('pkg'), method.receiver.class.name, method, false
    end

    def dig_map(map, depth)
      return map if depth == 0

      dig_map map[0][:children], depth - 1
    end
  end
end

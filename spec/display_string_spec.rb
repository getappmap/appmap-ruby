# frozen_string_literal: true

require 'spec_helper'
require 'appmap/event'

include AppMap

describe 'display_string' do
  def display_string(value)
    Event::MethodEvent.display_string value
  end

  def compare_display_string(value, expected)
    expect(display_string(value)).to eq(expected)
  end

  context 'for a' do
    it 'String' do
      compare_display_string 'foo', 'foo'
    end
    it 'long String' do
      compare_display_string 'foo' * 100, 'foo' * 33 + 'f (...200 more characters)'
    end
    it 'Array' do
      compare_display_string([ 1, 'my', :bar, [ 2, 3 ], { 4 => 5 } ], '[1, "my", :bar, [2, 3], {4=>5}]')
    end
    it 'Array with nil' do
      compare_display_string([ 1, nil, 3 ], '[1, nil, 3]')
    end
    it 'large Array' do
      compare_display_string 50.times.map { |i| i }, '[0, 1, 2, 3, 4, 5, 6, 7, 8, 9 (...40 more items)]'
    end
    it 'large Hash' do
      compare_display_string(50.times.map { |i| [ i*2, i*2+1] }.to_h, '{0=>1, 2=>3, 4=>5, 6=>7, 8=>9, 10=>11, 12=>13, 14=>15, 16=>17, 18=>19 (...40 more entries)}')
    end
    it 'Hash' do
      compare_display_string({ 1 => 2, 'my' => 'neighbor', bar: :baz, ary: [ 1, 2 ]}, '{1=>2, "my"=>"neighbor", :bar=>:baz, :ary=>[1, 2]}')
    end
    it 'big Hash' do
      compare_display_string(50.times.map { |i| [ i*2, i*2+1] }.to_h, '{0=>1, 2=>3, 4=>5, 6=>7, 8=>9, 10=>11, 12=>13, 14=>15, 16=>17, 18=>19 (...40 more entries)}')
    end
  end
end

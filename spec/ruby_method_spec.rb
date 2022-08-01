# frozen_string_literal: true

require 'spec_helper'

describe AppMap::Trace::RubyMethod do
  # These tests are mostly targeted towards Windows. Make sure no operating system errors go unhandled.
  describe :comment do
    # These methods use native implementations, and their source code files are not regular file paths.
    let(:methods) { [''.method(:unpack1), Kernel.instance_method(:eval)] }

    it 'properly handles invalid source file paths' do
      methods.each do |method|
        ruby_method = AppMap::Trace::RubyMethod.new(nil, nil, method, false)
        expect { ruby_method.comment }.not_to raise_error
      end
    end
  end
end

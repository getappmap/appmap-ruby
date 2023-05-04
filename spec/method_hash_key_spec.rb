require 'spec_helper'
require 'appmap/hook/method'

describe 'method_hash_key' do
  describe 'of a normal method' do
    it 'is a hash' do
      expect(AppMap::Hook.method_hash_key(AppMap::Hook, AppMap::Hook.method(:method_hash_key))).to be_a Integer
    end
  end
  describe 'when the class hash raises an error' do
    it 'is nil' do
      cls = Class.new do
        def say_hello; 'hello'; end

        class << self
          def hash
            raise TypeError, 'raise the type error needed by the test'
          end
        end
      end

      expect { cls.hash }.to raise_error(TypeError, 'raise the type error needed by the test')
      expect(AppMap::Hook.method_hash_key(cls, cls.new.method(:say_hello))).to be_nil
    end
  end
end
# frozen_string_literal: true

require 'rails_spec_helper'

describe 'AppMap class Hooking' do
  it 'hooks a new class' do
    require 'appmap/config'
    require 'appmap/hook'

    package = AppMap::Hook::Package.new('spec', [])
    config = AppMap::Hook::Config.new('hook_spec', [ package ])

    AppMap::Hook.hook(config)

    require 'appmap/trace/tracer'
    tracer = AppMap::Trace.tracers.trace

    class Foo
      def foo
        puts "foo"
      end

      def bar(x)
        puts "bar: #{x}"
        x
      end

      def baz(x: true)
        puts "baz: #{x}"
        x
      end

      def fizz(&block)
        puts "fizz: #{block.call}"
      end

      class << self
        def buzz
          puts "buzz"
        end
      end
    end

    Foo.new.foo
    Foo.new.bar(12)
    Foo.new.baz(x: 13)
    Foo.new.fizz { 14 }
    Foo.buzz

    # Not getting hooked
    klass = Class.new do
      define_method :to_s do
        "dynamically defined klass"
      end
    end

    puts klass.new.to_s

    while tracer.event?
      p tracer.next_event.to_h
    end
  end
end

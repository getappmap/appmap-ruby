# frozen_string_literal: true

require 'rails_spec_helper'
require 'appmap/hook'
require 'appmap/event'
require 'diffy'

describe 'AppMap class Hooking' do
  def collect_events(tracer)
    [].tap do |events|
      while tracer.event?
        events << tracer.next_event.to_h
      end
    end.map do |event|
      event.delete(:thread_id)
      event.delete(:elapsed)
      delete_object_id = ->(obj) { (obj || {}).delete(:object_id) }
      delete_object_id.call(event[:receiver])
      delete_object_id.call(event[:return_value])
      (event[:parameters] || []).each(&delete_object_id)
      (event[:exceptions] || []).each(&delete_object_id)

      if event[:event] == :return
        # These should be removed from the appmap spec
        %i[defined_class method_id path lineno static].each do |obsolete_field|
          event.delete(obsolete_field)
        end
      end
      event
    end.to_yaml
  end

  def invoke_test_file(file, &block)
    package = AppMap::Hook::Package.new(file, [])
    config = AppMap::Hook::Config.new('hook_spec', [ package ])
    AppMap::Hook.hook(config)

    tracer = AppMap.tracing.trace
    AppMap::Event.reset_id_counter
    begin
      load file
      yield
    ensure
      AppMap.tracing.delete(tracer)
    end
    [ config, tracer ]
  end

  def test_hook_behavior(file, events_yaml, &block)
    config, tracer = invoke_test_file(file, &block)

    events = collect_events(tracer)
    expect(Diffy::Diff.new(events, events_yaml).to_s).to eq('')

    [ config, tracer ]
  end

  it 'hooks an instance method that takes no arguments' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: InstanceMethod
      :method_id: say_default
      :path: spec/fixtures/hook/instance_method.rb
      :lineno: 8
      :static: false
      :parameters: []
      :receiver:
        :class: InstanceMethod
        :value: Instance Method fixture
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: default
    YAML
    config, tracer = test_hook_behavior 'spec/fixtures/hook/instance_method.rb', events_yaml do
      expect(InstanceMethod.new.say_default).to eq('default')
    end
  end

  it 'collects the methods that are invoked' do
    _, tracer = invoke_test_file 'spec/fixtures/hook/instance_method.rb' do
      InstanceMethod.new.say_default
    end
    expect(tracer.event_methods.to_a.map(&:defined_class)).to eq([ 'InstanceMethod' ])
    expect(tracer.event_methods.to_a.map(&:method).map(&:to_s)).to eq([ InstanceMethod.public_instance_method(:say_default).to_s ])
  end

  it 'builds a class map of invoked methods' do
    config, tracer = invoke_test_file 'spec/fixtures/hook/instance_method.rb' do
      InstanceMethod.new.say_default
    end
    class_map = AppMap.class_map(config, tracer.event_methods).to_yaml
    expect(Diffy::Diff.new(class_map, <<~YAML).to_s).to eq('')
    ---
    - :name: spec/fixtures/hook/instance_method.rb
      :type: package
      :children:
      - :name: InstanceMethod
        :type: class
        :children:
        - :name: say_default
          :type: function
          :location: spec/fixtures/hook/instance_method.rb:8
          :static: false
    YAML
  end

  it 'does not hook an attr_accessor' do
    events_yaml = <<~YAML
    --- []
    YAML
    test_hook_behavior 'spec/fixtures/hook/attr_accessor.rb', events_yaml do
      obj = AttrAccessor.new
      obj.value = 'foo'
      expect(obj.value).to eq('foo')
    end
  end

  it 'does not hook a constructor' do
    events_yaml = <<~YAML
    --- []
    YAML
    test_hook_behavior 'spec/fixtures/hook/constructor.rb', events_yaml do
      Constructor.new('foo')
    end
  end

  it 'hooks an instance method that takes an argument' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: InstanceMethod
      :method_id: say_echo
      :path: spec/fixtures/hook/instance_method.rb
      :lineno: 12
      :static: false
      :parameters:
      - :name: :arg
        :class: String
        :value: echo
        :kind: :req
      :receiver:
        :class: InstanceMethod
        :value: Instance Method fixture
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: echo
    YAML
    test_hook_behavior 'spec/fixtures/hook/instance_method.rb', events_yaml do
      expect(InstanceMethod.new.say_echo('echo')).to eq('echo')
    end
  end

  it 'hooks an instance method that takes a keyword argument' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: InstanceMethod
      :method_id: say_kw
      :path: spec/fixtures/hook/instance_method.rb
      :lineno: 16
      :static: false
      :parameters:
      - :name: :kw
        :class: Hash
        :value: '{:kw=>"kw"}'
        :kind: :key
      :receiver:
        :class: InstanceMethod
        :value: Instance Method fixture
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: kw
    YAML
    test_hook_behavior 'spec/fixtures/hook/instance_method.rb', events_yaml do
      expect(InstanceMethod.new.say_kw(kw: 'kw')).to eq('kw')
    end
  end

  it 'hooks an instance method that takes a default keyword argument' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: InstanceMethod
      :method_id: say_kw
      :path: spec/fixtures/hook/instance_method.rb
      :lineno: 16
      :static: false
      :parameters:
      - :name: :kw
        :class: NilClass
        :value: 
        :kind: :key
      :receiver:
        :class: InstanceMethod
        :value: Instance Method fixture
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: kw
    YAML
    test_hook_behavior 'spec/fixtures/hook/instance_method.rb', events_yaml do
      expect(InstanceMethod.new.say_kw).to eq('kw')
    end
  end

  it 'hooks an instance method that takes a block argument' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: InstanceMethod
      :method_id: say_block
      :path: spec/fixtures/hook/instance_method.rb
      :lineno: 20
      :static: false
      :parameters:
      - :name: :block
        :class: NilClass
        :value: 
        :kind: :block
      :receiver:
        :class: InstanceMethod
        :value: Instance Method fixture
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: albert
    YAML
    test_hook_behavior 'spec/fixtures/hook/instance_method.rb', events_yaml do
      expect(InstanceMethod.new.say_block { 'albert' }).to eq('albert')
    end
  end

  it 'hooks a singleton method' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: ClassMethod
      :method_id: say_default
      :path: spec/fixtures/hook/class_method.rb
      :lineno: 5
      :static: true
      :parameters: []
      :receiver:
        :class: Class
        :value: ClassMethod
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: default
    YAML
    test_hook_behavior 'spec/fixtures/hook/class_method.rb', events_yaml do
      expect(ClassMethod.say_default).to eq('default')
    end
  end

  it 'hooks a class method with explicit class name scope' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: ClassMethod
      :method_id: say_class_defined
      :path: spec/fixtures/hook/class_method.rb
      :lineno: 10
      :static: true
      :parameters: []
      :receiver:
        :class: Class
        :value: ClassMethod
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: defined with explicit class scope
    YAML
    test_hook_behavior 'spec/fixtures/hook/class_method.rb', events_yaml do
      expect(ClassMethod.say_class_defined).to eq('defined with explicit class scope')
    end
  end

  it "hooks a class method with 'self' as the class name scope" do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: ClassMethod
      :method_id: say_self_defined
      :path: spec/fixtures/hook/class_method.rb
      :lineno: 14
      :static: true
      :parameters: []
      :receiver:
        :class: Class
        :value: ClassMethod
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: defined with self class scope
    YAML
    test_hook_behavior 'spec/fixtures/hook/class_method.rb', events_yaml do
      expect(ClassMethod.say_self_defined).to eq('defined with self class scope')
    end
  end

  it 'Reports exceptions' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: ExceptionMethod
      :method_id: raise_exception
      :path: spec/fixtures/hook/exception_method.rb
      :lineno: 8
      :static: false
      :parameters: []
      :receiver:
        :class: ExceptionMethod
        :value: Exception Method fixture
    - :id: 2
      :event: :return
      :parent_id: 1
      :exceptions:
      - :class: RuntimeError
        :message: Exception occurred in raise_exception
        :path: spec/fixtures/hook/exception_method.rb
        :lineno: 9
    YAML
    test_hook_behavior 'spec/fixtures/hook/exception_method.rb', events_yaml do
      ExceptionMethod.new.raise_exception
    end
  end
end

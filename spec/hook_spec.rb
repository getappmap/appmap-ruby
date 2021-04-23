# frozen_string_literal: true

require 'rails_spec_helper'
require 'appmap/hook'
require 'appmap/event'
require 'diffy'

# Show nulls as the literal +null+, rather than just leaving the field
# empty. This make some of the expected YAML below easier to
# understand.
module ShowYamlNulls
  def visit_NilClass(o)
    @emitter.scalar('null', nil, 'tag:yaml.org,2002:null', true, false, Psych::Nodes::Scalar::ANY)
  end
end
Psych::Visitors::YAMLTree.prepend(ShowYamlNulls)

describe 'AppMap class Hooking', docker: false do
  require 'appmap/util'
  def collect_events(tracer)
    [].tap do |events|
      while tracer.event?
        events << tracer.next_event.to_h
      end
    end.map(&AppMap::Util.method(:sanitize_event))
  end

  def invoke_test_file(file, setup: nil, &block)
    AppMap.configuration = nil
    package = AppMap::Config::Package.build_from_path(file)
    config = AppMap::Config.new('hook_spec', [ package ])
    AppMap.configuration = config
    tracer = nil
    AppMap::Hook.new(config).enable do
      setup_result = setup.call if setup

      tracer = AppMap.tracing.trace
      AppMap::Event.reset_id_counter
      begin
        load file
        yield setup_result
      ensure
        AppMap.tracing.delete(tracer)
      end
    end

    [ config, tracer ]
  end

  def test_hook_behavior(file, events_yaml, setup: nil, &block)
    config, tracer = invoke_test_file(file, setup: setup, &block)

    events = collect_events(tracer).to_yaml

    expect(Diffy::Diff.new(events_yaml, events).to_s).to eq('') if events_yaml

    [ config, tracer, events ]
  end

  after do
    AppMap.configuration = nil
  end

  it 'excludes named classes and methods' do
    load 'spec/fixtures/hook/exclude.rb'
    package = AppMap::Config::Package.build_from_path('spec/fixtures/hook/exclude.rb')
    config = AppMap::Config.new('hook_spec', [ package ], %w[ExcludeTest])
    AppMap.configuration = config

    expect(config.never_hook?(ExcludeTest.new.method(:instance_method))).to be_truthy
    expect(config.never_hook?(ExcludeTest.method(:cls_method))).to be_truthy
  end

  it "handles an instance method named 'call' without issues" do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: MethodNamedCall
      :method_id: call
      :path: spec/fixtures/hook/method_named_call.rb
      :lineno: 8
      :static: false
      :parameters:
      - :name: :a
        :class: Integer
        :value: '1'
        :kind: :req
      - :name: :b
        :class: Integer
        :value: '2'
        :kind: :req
      - :name: :c
        :class: Integer
        :value: '3'
        :kind: :req
      - :name: :d
        :class: Integer
        :value: '4'
        :kind: :req
      - :name: :e
        :class: Integer
        :value: '5'
        :kind: :req
      :receiver:
        :class: MethodNamedCall
        :value: MethodNamedCall
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: 1 2 3 4 5
    YAML

    _, tracer = test_hook_behavior 'spec/fixtures/hook/method_named_call.rb', events_yaml do
      expect(MethodNamedCall.new.call(1, 2, 3, 4, 5)).to eq('1 2 3 4 5')
    end
    class_map = AppMap.class_map(tracer.event_methods)
    expect(Diffy::Diff.new(<<~CLASSMAP, YAML.dump(class_map)).to_s).to eq('')
    ---
    - :name: spec/fixtures/hook/method_named_call.rb
      :type: package
      :children:
      - :name: MethodNamedCall
        :type: class
        :children:
        - :name: call
          :type: function
          :location: spec/fixtures/hook/method_named_call.rb:8
          :static: false
    CLASSMAP
  end

  it 'can custom hook and label a function' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: CustomInstanceMethod
      :method_id: say_default
      :path: spec/fixtures/hook/custom_instance_method.rb
      :lineno: 8
      :static: false
      :parameters: []
      :receiver:
        :class: CustomInstanceMethod
        :value: CustomInstance Method fixture
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: default
    YAML

    config = AppMap::Config.load({
      functions: [
        {
          package: 'hook_spec',
          class: 'CustomInstanceMethod',
          functions: [ :say_default ],
          labels: ['cowsay']
        }
      ]
    }.deep_stringify_keys)

    load 'spec/fixtures/hook/custom_instance_method.rb'
    hook_cls = CustomInstanceMethod
    method = hook_cls.instance_method(:say_default)

    require 'appmap/hook/method'
    hook_method = AppMap::Hook::Method.new(config.package_for_method(method), hook_cls, method)
    hook_method.activate

    tracer = AppMap.tracing.trace
    AppMap::Event.reset_id_counter
    begin
      expect(CustomInstanceMethod.new.say_default).to eq('default')
    ensure
      AppMap.tracing.delete(tracer)
    end

    events = collect_events(tracer).to_yaml

    expect(Diffy::Diff.new(events_yaml, events).to_s).to eq('')
    class_map = AppMap.class_map(tracer.event_methods)
    expect(Diffy::Diff.new(<<~CLASSMAP, YAML.dump(class_map)).to_s).to eq('')
    ---
    - :name: hook_spec
      :type: package
      :children:
      - :name: CustomInstanceMethod
        :type: class
        :children:
        - :name: say_default
          :type: function
          :location: spec/fixtures/hook/custom_instance_method.rb:8
          :static: false
          :labels:
          - cowsay
    CLASSMAP
  end

  it 'parses labels from comments' do
    _, tracer = invoke_test_file 'spec/fixtures/hook/labels.rb' do
      ClassWithLabel.new.fn_with_label
    end
    class_map = AppMap.class_map(tracer.event_methods).to_yaml
    expect(Diffy::Diff.new(<<~YAML, class_map).to_s).to eq('')
    ---
    - :name: spec/fixtures/hook/labels.rb
      :type: package
      :children:
      - :name: ClassWithLabel
        :type: class
        :children:
        - :name: fn_with_label
          :type: function
          :location: spec/fixtures/hook/labels.rb:4
          :static: false
          :labels:
          - has-fn-label
          :comment: "# @label has-fn-label\\n"
          :source: |2
              def fn_with_label
              end
      YAML
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
    test_hook_behavior 'spec/fixtures/hook/instance_method.rb', events_yaml do
      expect(InstanceMethod.new.say_default).to eq('default')
    end
  end

  it 'collects the methods that are invoked' do
    _, tracer = invoke_test_file 'spec/fixtures/hook/instance_method.rb' do
      InstanceMethod.new.say_default
    end
    expect(tracer.event_methods.to_a.map(&:defined_class)).to eq([ 'InstanceMethod' ])
    expect(tracer.event_methods.to_a.map(&:to_s)).to eq([ InstanceMethod.public_instance_method(:say_default).to_s ])
  end

  it 'builds a class map of invoked methods' do
    _, tracer = invoke_test_file 'spec/fixtures/hook/instance_method.rb' do
      InstanceMethod.new.say_default
    end
    class_map = AppMap.class_map(tracer.event_methods).to_yaml
    expect(Diffy::Diff.new(<<~YAML, class_map).to_s).to eq('')
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
          :source: |2
              def say_default
                'default'
              end
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
        :class: String
        :value: kw
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
        :value: null
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

  it 'hooks an instance method that takes keyword arguments' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: InstanceMethod
      :method_id: say_kws
      :path: spec/fixtures/hook/instance_method.rb
      :lineno: 20
      :static: false
      :parameters:
      - :name: :args
        :class: Array
        :value: "[4, 5]"
        :kind: :rest
      - :name: :kw1
        :class: String
        :value: one
        :kind: :keyreq
      - :name: :kw2
        :class: Integer
        :value: '2'
        :kind: :key
      - :name: :kws
        :class: Hash
        :value: "{:kw3=>:three}"
        :kind: :keyrest
      :receiver:
        :class: InstanceMethod
        :value: Instance Method fixture
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: one2{:kw3=>:three}45
    YAML
    test_hook_behavior 'spec/fixtures/hook/instance_method.rb', events_yaml do
      expect(InstanceMethod.new.say_kws(4, 5, kw1: 'one', kw2: 2, kw3: :three)).to eq('one2{:kw3=>:three}45')
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
      :lineno: 24
      :static: false
      :parameters:
      - :name: :block
        :class: NilClass
        :value: null
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
      :defined_class: SingletonMethod
      :method_id: say_default
      :path: spec/fixtures/hook/singleton_method.rb
      :lineno: 5
      :static: true
      :parameters: []
      :receiver:
        :class: Class
        :value: SingletonMethod
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: default
    YAML
    test_hook_behavior 'spec/fixtures/hook/singleton_method.rb', events_yaml do
      expect(SingletonMethod.say_default).to eq('default')
    end
  end

  it 'hooks a class method with explicit class name scope' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: SingletonMethod
      :method_id: say_class_defined
      :path: spec/fixtures/hook/singleton_method.rb
      :lineno: 10
      :static: true
      :parameters: []
      :receiver:
        :class: Class
        :value: SingletonMethod
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: defined with explicit class scope
    YAML
    test_hook_behavior 'spec/fixtures/hook/singleton_method.rb', events_yaml do
      expect(SingletonMethod.say_class_defined).to eq('defined with explicit class scope')
    end
  end

  it "hooks a class method with 'self' as the class name scope" do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: SingletonMethod
      :method_id: say_self_defined
      :path: spec/fixtures/hook/singleton_method.rb
      :lineno: 14
      :static: true
      :parameters: []
      :receiver:
        :class: Class
        :value: SingletonMethod
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: defined with self class scope
    YAML
    test_hook_behavior 'spec/fixtures/hook/singleton_method.rb', events_yaml do
      expect(SingletonMethod.say_self_defined).to eq('defined with self class scope')
    end
  end


  it 'hooks an included method' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: SingletonMethod
      :method_id: added_method
      :path: spec/fixtures/hook/singleton_method.rb
      :lineno: 21
      :static: false
      :parameters: []
      :receiver:
        :class: SingletonMethod
        :value: Singleton Method fixture
    - :id: 2
      :event: :call
      :defined_class: SingletonMethod::AddMethod
      :method_id: _added_method
      :path: spec/fixtures/hook/singleton_method.rb
      :lineno: 27
      :static: false
      :parameters: []
      :receiver:
        :class: SingletonMethod
        :value: Singleton Method fixture
    - :id: 3
      :event: :return
      :parent_id: 2
      :return_value:
        :class: String
        :value: defined by including a module
    - :id: 4
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: defined by including a module
    YAML

    load 'spec/fixtures/hook/singleton_method.rb'
    setup = -> { SingletonMethod.new.do_include }
    test_hook_behavior 'spec/fixtures/hook/singleton_method.rb', events_yaml, setup: setup do |s|
      expect(s.added_method).to eq('defined by including a module')
    end
  end

  it "doesn't hook a singleton method defined for an instance" do
    # Ideally, Ruby would fire a TracePoint event when a singleton
    # class gets created by defining a method on an instance. It
    # currently doesn't, though, so there's no way for us to hook such
    # a method.
    #
    # This example will fail if Ruby's behavior changes at some point
    # in the future.
    events_yaml = <<~YAML
    --- []
    YAML

    load 'spec/fixtures/hook/singleton_method.rb'
    setup = -> { SingletonMethod.new_with_instance_method }
    test_hook_behavior 'spec/fixtures/hook/singleton_method.rb', events_yaml, setup: setup do |s|
      # Make sure we're testing the right thing
      say_instance_defined = s.method(:say_instance_defined)
      expect(say_instance_defined.owner.to_s).to start_with('#<Class:#<SingletonMethod:')

      # Verify the native extension works as expected
      expect(AppMap::Hook.singleton_method_owner_name(say_instance_defined)).to eq('SingletonMethod')

      expect(s.say_instance_defined).to eq('defined for an instance')
    end
  end

  it 'hooks a singleton method on an embedded struct' do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: SingletonMethod::STRUCT_TEST
      :method_id: say_struct_singleton
      :path: spec/fixtures/hook/singleton_method.rb
      :lineno: 52
      :static: true
      :parameters: []
      :receiver:
        :class: Class
        :value: SingletonMethod::STRUCT_TEST
    - :id: 2
      :event: :return
      :parent_id: 1
      :return_value:
        :class: String
        :value: singleton for a struct
    YAML

    test_hook_behavior 'spec/fixtures/hook/singleton_method.rb', events_yaml do
      expect(SingletonMethod::STRUCT_TEST.say_struct_singleton).to eq('singleton for a struct')
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
      begin
        ExceptionMethod.new.raise_exception
      rescue
        # don't let the exception fail the test
      end
    end
  end

  context 'string conversions works for the receiver when' do

    it 'is missing #to_s' do
      events_yaml = <<~YAML
      ---
      - :id: 1
        :event: :call
        :defined_class: NoToSMethod
        :method_id: say_hello
        :path: spec/fixtures/hook/exception_method.rb
        :lineno: 32
        :static: false
        :parameters: []
        :receiver:
          :class: Class
          :value: NoToSMethod
      - :id: 2
        :event: :return
        :parent_id: 1
        :return_value:
          :class: String
          :value: hello
      YAML

      test_hook_behavior 'spec/fixtures/hook/exception_method.rb', events_yaml do
        inst = NoToSMethod.new
        # sanity check
        expect(inst).not_to respond_to(:to_s)
        inst.say_hello
      end
    end

    it 'it is missing #to_s and it raises an exception in #inspect' do
      events_yaml = <<~YAML
      ---
      - :id: 1
        :event: :call
        :defined_class: InspectRaises
        :method_id: say_hello
        :path: spec/fixtures/hook/exception_method.rb
        :lineno: 42
        :static: false
        :parameters: []
        :receiver:
          :class: Class
          :value: "*Error inspecting variable*"
      - :id: 2
        :event: :return
        :parent_id: 1
        :return_value:
          :class: String
          :value: hello
      YAML

      test_hook_behavior 'spec/fixtures/hook/exception_method.rb', events_yaml do
        inst = InspectRaises.new
        # sanity check
        expect(inst).not_to respond_to(:to_s)
        inst.say_hello
      end
    end

    it 'it raises an exception in #to_s' do
      events_yaml = <<~YAML
      ---
      - :id: 1
        :event: :call
        :defined_class: ToSRaises
        :method_id: say_hello
        :path: spec/fixtures/hook/exception_method.rb
        :lineno: 52
        :static: false
        :parameters: []
        :receiver:
          :class: ToSRaises
          :value: "*Error inspecting variable*"
      - :id: 2
        :event: :return
        :parent_id: 1
        :return_value:
          :class: String
          :value: hello
      YAML

      test_hook_behavior 'spec/fixtures/hook/exception_method.rb', events_yaml do
        ToSRaises.new.say_hello
      end
    end
  end

  it 're-raises exceptions' do
    RSpec::Expectations.configuration.on_potential_false_positives = :nothing

    invoke_test_file 'spec/fixtures/hook/exception_method.rb' do
      expect { ExceptionMethod.new.raise_exception }.to raise_exception
    end
  end

  context 'ActiveSupport::SecurityUtils.secure_compare' do
    it 'is hooked' do
      events_yaml = <<~YAML
      ---
      - :id: 1
        :event: :call
        :defined_class: Compare
        :method_id: compare
        :path: spec/fixtures/hook/compare.rb
        :lineno: 4
        :static: true
        :parameters:
        - :name: :s1
          :class: String
          :value: string
          :kind: :req
        - :name: :s2
          :class: String
          :value: string
          :kind: :req
        :receiver:
          :class: Class
          :value: Compare
      - :id: 2
        :event: :call
        :defined_class: ActiveSupport::SecurityUtils
        :method_id: secure_compare
        :path: lib/active_support/security_utils.rb
        :lineno: 26
        :static: true
        :parameters:
        - :name: :a
          :class: String
          :value: string
          :kind: :req
        - :name: :b
          :class: String
          :value: string
          :kind: :req
        :receiver:
          :class: Module
          :value: ActiveSupport::SecurityUtils
      - :id: 3
        :event: :call
        :defined_class: Digest::Instance
        :method_id: digest
        :path: Digest::Instance#digest
        :static: false
        :parameters:
        - :name: arg
          :class: Array
          :value: '["string"]'
          :kind: :rest
        :receiver:
          :class: Digest::SHA256
          :value: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      - :id: 4
        :event: :return
        :parent_id: 3
        :return_value:
          :class: String
          :value: "G2__)__qc____X____3_].\\x02y__.___/_"
      - :id: 5
        :event: :call
        :defined_class: Digest::Instance
        :method_id: digest
        :path: Digest::Instance#digest
        :static: false
        :parameters:
        - :name: arg
          :class: Array
          :value: '["string"]'
          :kind: :rest
        :receiver:
          :class: Digest::SHA256
          :value: e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855
      - :id: 6
        :event: :return
        :parent_id: 5
        :return_value:
          :class: String
          :value: "G2__)__qc____X____3_].\\x02y__.___/_"
      - :id: 7
        :event: :return
        :parent_id: 2
        :return_value:
          :class: TrueClass
          :value: 'true'
      - :id: 8
        :event: :return
        :parent_id: 1
        :return_value:
          :class: TrueClass
          :value: 'true'
      YAML

      _, _, events = test_hook_behavior 'spec/fixtures/hook/compare.rb', nil do
        expect(Compare.compare('string', 'string')).to be_truthy
      end
      secure_compare_event = YAML.load(events).find { |evt| evt[:defined_class] == 'ActiveSupport::SecurityUtils' }
      secure_compare_event.delete(:lineno)

      expect(Diffy::Diff.new(<<~YAML, secure_compare_event.to_yaml).to_s).to eq('')
      ---
      :id: 2
      :event: :call
      :defined_class: ActiveSupport::SecurityUtils
      :method_id: secure_compare
      :path: lib/active_support/security_utils.rb
      :static: true
      :parameters:
      - :name: :a
        :class: String
        :value: string
        :kind: :req
      - :name: :b
        :class: String
        :value: string
        :kind: :req
      :receiver:
        :class: Module
        :value: ActiveSupport::SecurityUtils
      YAML
    end

    it 'gets labeled in the classmap' do
      classmap_yaml = <<~YAML
      ---
      - :name: spec/fixtures/hook/compare.rb
        :type: package
        :children:
        - :name: Compare
          :type: class
          :children:
          - :name: compare
            :type: function
            :location: spec/fixtures/hook/compare.rb:4
            :static: true
            :source: |2
                def self.compare(s1, s2)
                  ActiveSupport::SecurityUtils.secure_compare(s1, s2)
                end
      - :name: active_support
        :type: package
        :children:
        - :name: ActiveSupport
          :type: class
          :children:
          - :name: SecurityUtils
            :type: class
            :children:
            - :name: secure_compare
              :type: function
              :location: lib/active_support/security_utils.rb:26
              :static: true
              :labels:
              - security
              - crypto
              :comment: |
                # Constant time string comparison, for variable length strings.
                #
                # The values are first processed by SHA256, so that we don't leak length info
                # via timing attacks.
              :source: |2
                    def secure_compare(a, b)
                      fixed_length_secure_compare(::Digest::SHA256.digest(a), ::Digest::SHA256.digest(b)) && a == b
                    end
      - :name: openssl
        :type: package
        :children:
        - :name: Digest
          :type: class
          :children:
          - :name: Instance
            :type: class
            :children:
            - :name: digest
              :type: function
              :location: Digest::Instance#digest
              :static: false
              :labels:
              - security
              - crypto
      YAML

      _, tracer = invoke_test_file 'spec/fixtures/hook/compare.rb' do
        expect(Compare.compare('string', 'string')).to be_truthy
      end
      cm = AppMap::Util.sanitize_paths(AppMap::ClassMap.build_from_methods(tracer.event_methods))
      entry = cm[1][:children][0][:children][0][:children][0]
      # Sanity check, make sure we got the right one
      expect(entry[:name]).to eq('secure_compare')
      expect(entry[:labels]).to eq(%w[provider.secure_compare])
    end
  end

  it "doesn't cause expectations on Time.now to fail" do
    events_yaml = <<~YAML
    ---
    - :id: 1
      :event: :call
      :defined_class: InstanceMethod
      :method_id: say_the_time
      :path: spec/fixtures/hook/instance_method.rb
      :lineno: 28
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
        :value: '2020-01-01 00:00:00 +0000'
    YAML
    test_hook_behavior 'spec/fixtures/hook/instance_method.rb', events_yaml do
      require 'timecop'
      begin
        tz = ENV['TZ']
        ENV['TZ'] = 'UTC'
        Timecop.freeze(Time.utc('2020-01-01')) do
          expect(Time).to receive(:now).exactly(3).times.and_call_original
          expect(InstanceMethod.new.say_the_time).to be
        end
      ensure
        ENV['TZ'] = tz
      end
    end
  end

  it "preserves the arity of hooked methods" do
    invoke_test_file 'spec/fixtures/hook/instance_method.rb' do
      expect(InstanceMethod.instance_method(:say_echo).arity).to be(1)
      expect(InstanceMethod.new.method(:say_echo).arity).to be(1)
    end
  end
end

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
    end.map(&AppMap::Util.method(:sanitize_event)).to_yaml
  end

  def invoke_test_file(file, setup: nil, &block)
    AppMap.configuration = nil
    package = AppMap::Package.new(file, nil, [])
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

    events = collect_events(tracer)
    expect(Diffy::Diff.new(events, events_yaml).to_s).to eq('')

    [ config, tracer ]
  end

  after do
    AppMap.configuration = nil
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
      :lineno: 44
      :static: false
      :parameters: []
      :receiver:
        :class: SingletonMethod
        :value: Singleton Method fixture
    - :id: 2
      :event: :call
      :defined_class: AddMethod
      :method_id: _added_method
      :path: spec/fixtures/hook/singleton_method.rb
      :lineno: 50
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
      expect(s.say_instance_defined).to eq('defined for an instance')
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
        :path: gems/activesupport-6.0.3.2/lib/active_support/security_utils.rb
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
        :event: :return
        :parent_id: 2
        :return_value:
          :class: TrueClass
          :value: 'true'
      - :id: 4
        :event: :return
        :parent_id: 1
        :return_value:
          :class: TrueClass
          :value: 'true'
      YAML

      test_hook_behavior 'spec/fixtures/hook/compare.rb', events_yaml do
        expect(Compare.compare('string', 'string')).to be_truthy
      end
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
              :location: gems/activesupport-6.0.3.2/lib/active_support/security_utils.rb:26
              :static: true
              :labels:
              - security
      YAML

      config, tracer = invoke_test_file 'spec/fixtures/hook/compare.rb' do
        expect(Compare.compare('string', 'string')).to be_truthy
      end
      cm = AppMap::ClassMap.build_from_methods(config, tracer.event_methods)
      entry = cm[1][:children][0][:children][0][:children][0]
      # Sanity check, make sure we got the right one
      expect(entry[:name]).to eq('secure_compare')
      spec = Gem::Specification.find_by_name('activesupport')
      entry[:location].gsub!(spec.base_dir + '/', '')
      expect(Diffy::Diff.new(cm.to_yaml, classmap_yaml).to_s).to eq('')
    end
  end
end

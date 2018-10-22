require 'test_helper'
require 'appmap'
require 'appmap/config'
require 'appmap/inspector'
require 'appmap/trace/tracer'

class TraceTest < Minitest::Test
  # Runs a sequence of pre-recorded events and ensures that 
  def test_trace_web_request
    config_yaml = <<-CONFIG
    lib/appmap:
      type: module
      module_name: appmap
      exclude:
        - appmap/server

    examples:
      type: module
      module_name: examples
    CONFIG

    events = %q(
    {"id":1,"event":"call","defined_class":"MockWebapp::Controller","method_id":"instance","path":"/Users/kgilpin/Documents/appland/appmap-ruby/examples/mock_webapp/controller.rb","lineno":11,"static":true,"thread_id":70291791492740,"variables":{"self":{"class":"Class","value":"MockWebapp::Controller","object_id":70291792083700},"variables":{}}}
    {"id":2,"event":"return","defined_class":"MockWebapp::Controller","method_id":"instance","path":"/Users/kgilpin/Documents/appland/appmap-ruby/examples/mock_webapp/controller.rb","lineno":13,"static":true,"thread_id":70291791492740,"variables":{"self":{"class":"Class","value":"MockWebapp::Controller","object_id":70291792083700},"return_value":{"class":"MockWebapp::Controller","value":"#\u003cMockWebapp::Controller:0x00007fdc2a9868c8\u003e","object_id":70291792082020}},"parent_id":1,"elapsed":6.0e-06}
    {"id":3,"event":"call","defined_class":"MockWebapp::Request","method_id":"initialize","path":"/Users/kgilpin/Documents/appland/appmap-ruby/examples/mock_webapp/request.rb","lineno":8,"static":false,"thread_id":70291791492740,"variables":{"self":{"class":"MockWebapp::Request","value":"#\u003cstruct MockWebapp::Request params=nil\u003e","object_id":70291792081100},"variables":{"args":{"class":"Array","value":"[{:id=\u003e\"alice\"}]","object_id":70291792081060}}}}
    {"id":4,"event":"return","defined_class":"MockWebapp::Request","method_id":"initialize","path":"/Users/kgilpin/Documents/appland/appmap-ruby/examples/mock_webapp/request.rb","lineno":10,"static":false,"thread_id":70291791492740,"variables":{"self":{"class":"MockWebapp::Request","value":"#\u003cstruct MockWebapp::Request params={:id=\u003e\"alice\"}\u003e","object_id":70291792081100},"return_value":{"class":"NilClass","value":null,"object_id":8}},"parent_id":3,"elapsed":3.0e-06}
    {"id":5,"event":"call","defined_class":"MockWebapp::Controller","method_id":"process","path":"/Users/kgilpin/Documents/appland/appmap-ruby/examples/mock_webapp/controller.rb","lineno":17,"static":false,"thread_id":70291791492740,"variables":{"self":{"class":"MockWebapp::Controller","value":"#\u003cMockWebapp::Controller:0x00007fdc2a9868c8\u003e","object_id":70291792082020},"variables":{"request":{"class":"MockWebapp::Request","value":"#\u003cstruct MockWebapp::Request params={:id=\u003e\"alice\"}\u003e","object_id":70291792081100}}}}
    {"id":6,"event":"call","defined_class":"MockWebapp::User","method_id":"find","path":"/Users/kgilpin/Documents/appland/appmap-ruby/examples/mock_webapp/user.rb","lineno":13,"static":true,"thread_id":70291791492740,"variables":{"self":{"class":"Class","value":"MockWebapp::User","object_id":70291792098860},"variables":{"id":{"class":"String","value":"alice","object_id":70291792081140}}}}
    {"id":7,"event":"return","defined_class":"MockWebapp::User","method_id":"find","path":"/Users/kgilpin/Documents/appland/appmap-ruby/examples/mock_webapp/user.rb","lineno":15,"static":true,"thread_id":70291791492740,"variables":{"self":{"class":"Class","value":"MockWebapp::User","object_id":70291792098860},"return_value":{"class":"MockWebapp::User","value":"#\u003cstruct MockWebapp::User login=\"alice\"\u003e","object_id":70291792098760}},"parent_id":6,"elapsed":2.0e-06}
    {"id":8,"event":"return","defined_class":"MockWebapp::Controller","method_id":"process","path":"/Users/kgilpin/Documents/appland/appmap-ruby/examples/mock_webapp/controller.rb","lineno":21,"static":false,"thread_id":70291791492740,"variables":{"self":{"class":"MockWebapp::Controller","value":"#\u003cMockWebapp::Controller:0x00007fdc2a9868c8\u003e","object_id":70291792082020},"return_value":{"class":"Hash","value":"{:login=\u003e\"alice\"}","object_id":70291792075560}},"parent_id":5,"elapsed":0.000263}
    )

    require 'yaml'
    config = AppMap::Config.load YAML.safe_load(config_yaml)
    annotations = config.map(&AppMap::Inspector.method(:detect_annotations)).flatten
    methods = annotations.map(&:collect_methods).flatten

    def method_call_from_event(evt)
      AppMap::Trace::MethodCall.new(evt.id, evt.event.intern, evt.defined_class, evt.method_id, evt.path, evt.lineno, evt.static, evt.thread_id, evt.variables)
    end

    def method_return_from_event(evt, parent_id, elapsed)
      AppMap::Trace::MethodReturn.new(evt.id, evt.event.intern, evt.defined_class, evt.method_id, evt.path, evt.lineno, evt.static, evt.thread_id, evt.variables).tap do |mr|
        assert_equal parent_id, evt.parent_id
        mr.parent_id = evt.parent_id
        mr.elapsed = evt.elapsed
      end
    end

    tracer = AppMap::Trace::Tracer.new(methods)
    handler = AppMap::Trace::TracePointHandler.new(tracer)
    handler.call_constructor = method(:method_call_from_event)
    handler.return_constructor = method(:method_return_from_event)

    events = events
             .split("\n")
             .map(&:strip)
             .reject(&:empty?)
             .map(&JSON.method(:parse))

    events.each do |evt_hash|
      evt = OpenStruct.new(evt_hash.dup)
      evt['event'] = evt['event'].intern
      handler.handle evt
    end

    i = 0
    while tracer.event?
      event = tracer.next_event
      assert_equal events[i], JSON.parse(event.to_h.to_json)
      i += 1
    end
  end
end

require 'test_helper'

class TraceTest < Minitest::Test
  class << self
    def build_tracer(program_file_path)
      require 'appmap/inspect'
      features = AppMap::Inspect.inspect_file(:implicit, file_path: program_file_path).flatten
      methods = features.map(&:collect_methods).flatten
      require 'appmap/trace/tracer'
      AppMap::Trace.tracer = AppMap::Trace::Tracer.new(methods)
    end
  end

  def test_print_to_stdout
    program_file_path = File.absolute_path('test/fixtures/trace_test/trace_program_1.rb')
    tracer = self.class.build_tracer(program_file_path)
    AppMap::Trace::Tracer.trace tracer

    load program_file_path

    printer = Fixtures::TraceTest::TraceProgram1::Printer::Stdout.new
    Fixtures::TraceTest::TraceProgram1::Main.new(printer).say("hello")

    events = []
    while tracer.event?
      events << tracer.next_event
    end

    assert_equal JSON.pretty_generate(JSON.parse(<<-JSON)), JSON.pretty_generate(extract_summary(events))
    [
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Main","method_id":"initialize","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":5,"static":false},
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Main","method_id":"say","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":9,"static":false},
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Printer::Stdout","method_id":"say","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":17,"static":false}
    ]
    JSON
  end

  def test_print_to_stderr
    program_file_path = File.absolute_path('test/fixtures/trace_test/trace_program_1.rb')
    tracer = self.class.build_tracer(program_file_path)
    AppMap::Trace::Tracer.trace tracer

    load program_file_path

    # printer = Fixtures::TraceTest::TraceProgram1::Printer.make_stderr_printer
    printer = Fixtures::TraceTest::TraceProgram1::Printer::Stderr
    Fixtures::TraceTest::TraceProgram1::Main.new(printer).say("hello")

    events = []
    while tracer.event?
      events << tracer.next_event
    end

    assert_equal JSON.pretty_generate(JSON.parse(<<-JSON)), JSON.pretty_generate(extract_summary(events))
    [
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Main","method_id":"initialize","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":5,"static":false},
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Main","method_id":"say","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":9,"static":false},
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Printer::Stderr","method_id":"say","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":25,"static":true}
    ]
    JSON
  end

  def test_print_to_stderr_via_instance_sclass
    program_file_path = File.absolute_path('test/fixtures/trace_test/trace_program_1.rb')
    tracer = self.class.build_tracer(program_file_path)
    AppMap::Trace::Tracer.trace tracer

    load program_file_path

    printer = Fixtures::TraceTest::TraceProgram1::Printer.make_stderr_printer

    Fixtures::TraceTest::TraceProgram1::Main.new(printer).say("hello")

    events = []
    while tracer.event?
      events << tracer.next_event
    end

    assert_equal JSON.pretty_generate(JSON.parse(<<-JSON)), JSON.pretty_generate(extract_summary(events))
    [
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Printer","method_id":"make_stderr_printer","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":32,"static":true},
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Main","method_id":"initialize","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":5,"static":false},
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Main","method_id":"say","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":9,"static":false},
      {"defined_class":"Fixtures::TraceTest::TraceProgram1::Printer::Stdout","method_id":"say","path":"/Users/kgilpin/Documents/appland/appmap-ruby/test/fixtures/trace_test/trace_program_1.rb","lineno":35,"static":true}
    ]
    JSON
  end

  def extract_summary(events)
    events.select { |e| e.event == :call }
      .map(&:to_h)
      .map { |h| h.keep_if { |k, _| %i[defined_class method_id path lineno static].member?(k) } }
  end
end

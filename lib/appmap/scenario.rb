module AppMap
  # Captures a line-by-line invocation of a program.
  class Scenario
    CallStruct = Struct.new(:class_name, :method_name, :static, :depth, :elapsed)

    # A single method call within a scenario.
    class Call < CallStruct
      alias static? static

      def children
        @children ||= []
      end

      def to_h
        super.to_h.tap do |h|
          h[:children] = children.map(&:to_h) unless children.empty?
        end
      end
    end

    attr_reader :calls

    def initialize(calls)
      @calls = calls
    end

    def to_json(*opts)
      to_h.to_json(*opts)
    end

    def to_h
      {
        calls: calls.map(&:to_h)
      }
    end

    class << self
      # Load the scenario from an rbtrace text file.
      # Example:
      # # Crawl github.com/postgres
      # Crawler::Action::Run.initialize <0.005501>
      # Crawler::Action::Run#initialize <0.000671>
      # Crawler::Action::Run#perform
      #   Crawler::Provider::GitHub#org_repositories
      #     Crawler::Cache::TTLIgnoringCache#process
      #       Crawler::Cache::SQLCache#read <0.001168>
      #       Crawler::Cache::SQLCache#read <0.001272>
      #       Crawler::Cache::SQLCache#write <0.026589>
      #     Crawler::Cache::TTLIgnoringCache#process <0.292458>
      #   Crawler::Provider::GitHub#org_repositories <0.376040>
      # Crawler::Action::Run#perform <16.409675>      
      def parse_rbtrace(trace)
        lines = trace.split("\n").select do |line|
          !line.empty? && line[0] != '#'
        end
        Scenario.new parse_rbtrace_lines(lines)
      end

      protected

      def parse_rbtrace_lines(lines)
        parents = []
        calls = []
        lines.each do |line|
          call = parse_call(line)
          if parents.empty?
            calls << call
            parents << call unless call.elapsed
          else
            parent = parents.last
            if call.depth > parent.depth
              parent.children << call
              parents << call unless call.elapsed
            else # call.depth <= parent.depth
              parent.elapsed = call.elapsed
              parents.pop
            end
          end
        end
        calls
      end

      def parse_call(line)
        space = body = class_name = separator = method_name = nil
        line.match(/^(\s*)(.*)/).tap do |md|
          space = md[1]
          body = md[2]
        end
        method, elapsed = body.split
        elapsed = elapsed.match(/^\<([.\d]+)\>/)[1].to_f if elapsed
        method.match(/^([^.#]+)([.#])(.*)/).tap do |md|
          class_name = md[1]
          separator = md[2]
          method_name = md[3]
        end
        depth = space.length / 2
        Call.new(class_name, method_name, separator == '.', depth, elapsed)
      end
    end
  end
end

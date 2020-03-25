# frozen_string_literal: true

require 'parser/current'
require 'set'

module AppMap
  class Parser
    def initialize(file_path: nil, code: nil)
      @file_path = file_path
      @code = code
    end

    def to_s
      "Parse code #{file_path.inspect}"
    end

    # Parse the contents of a file into a list of features.
    def parse
      parse_tree, comments = parse_code_and_comments
      parse_nodes = build_parse_nodes parse_tree
      [ parse_nodes, comments ]
    end

    protected

    def file_path
      @file_path || '<inline>'
    end

    def code
      @code ||= File.read(file_path)
    end

    def parse_code_and_comments
      ::Parser::CurrentRuby.parse_with_comments(code)
    rescue ::Parser::SyntaxError, EncodingError
      warn "Unable to parse #{file_path.inspect} : #{$!.message}"
      [ [], [] ]
    end

    # rubocop:disable Metrics/MethodLength
    def build_parse_nodes(parse_tree)
      parse_nodes = []
      visit_methods = lambda do |node, ancestors|
        return unless node.respond_to?(:type)

        parse_node = build_parse_node(node, file_path, ancestors)
        parse_nodes << parse_node if parse_node

        ancestors << node
        node.children.each do |child|
          visit_methods.call(child, ancestors)
        end
        ancestors.pop
      end
      visit_methods.call(parse_tree, [])
      parse_nodes
    end
  end
  # rubocop:enable Metrics/MethodLength
end


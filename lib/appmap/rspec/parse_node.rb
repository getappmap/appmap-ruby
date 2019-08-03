require 'forwardable'

module AppMap
  module RSpec
    # ParseNodeStruct wraps a generic AST parse node.
    ParseNodeStruct = Struct.new(:node, :file_path, :ancestors) do
    end

    # ParseNode wraps a generic AST parse node.
    class ParseNode < ParseNodeStruct
      extend Forwardable

      def_delegators :node, :type, :location

      class << self
        # Build a ParseNode from an AST node.
        def from_node(node, file_path, ancestors)
          case node.type
          when :block
            BlockParseNode.new(node, file_path, ancestors.dup)
          end
        end
      end
    end

    # A Ruby block.
    class BlockParseNode < ParseNode
      def to_s
        "RSpec block at #{file_path} #{first_line}:#{last_line}"
      end

      def first_line
        node.location.first_line
      end

      def last_line
        node.location.last_line
      end
    end
  end
end

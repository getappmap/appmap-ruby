require 'parser/current'
require 'set'

require 'appmap/annotation'

module AppMap
  # @appmap
  class Inspector
    class << self
      # Inspect the filesystem for annotations.
      #
      # @appmap
      def inspect(config)
        children = config.children.map(&Inspector.method(:inspect)).flatten.compact

        if config.annotated?
          AppMap::Inspector.new(config.path).parse.tap do |annotations|
            annotations.each do |annot|
              annot.children ||= []
              annot.children += children
            end
          end
        elsif config.module?
          AppMap::Annotation::Module.new(config.module_name, config.path, {}, children)
        end
      end
    end

    attr_reader :file_path

    ParseNode = Struct.new(:node, :file_path, :ancestors) do # :nodoc:
      extend Forwardable

      def_delegators :node, :type, :location

      class << self
        def from_node(node, file_path, ancestors)
          case node.type
          when :class
            ClassParseNode.new(node, file_path, ancestors.dup)
          when :def
            InstanceMethodParseNode.new(node, file_path, ancestors.dup)
          when :defs
            StaticMethodParseNode.new(node, file_path, ancestors.dup)
          end
        end
      end

      # Gets the AST node of the module or class which encloses this node.
      def enclosing_type_node
        ancestors.reverse.find do |a|
          %i[class module].include?(a.type)
        end
      end

      def parent_node
        ancestors[-1]
      end

      def preceding_sibling_nodes
        index_of_this_node = parent_node.children.index { |c| c == node }
        parent_node.children[0...index_of_this_node]
      end

      protected

      def extract_class_name(node)
        node.children[0].children[1].to_s
      end

      def extract_module_name(node)
        node.children[0].children[1].to_s
      end
    end

    # A Ruby class.
    class ClassParseNode < ParseNode
      def to_annotation(attributes)
        AppMap::Annotation::Cls.new(extract_class_name(node), "#{file_path}:#{location.line}", attributes, [])
      end
    end

    # Abstract representation of a method.
    class MethodParseNode < ParseNode
      def to_annotation(attributes)
        AppMap::Annotation::Method.new(name, "#{file_path}:#{location.line}", attributes, []).tap do |a|
          a.static = static?
          a.class_name = class_name
        end
      end

      def enclosing_names
        ancestors.select do |a|
          %i[class module].include?(a.type)
        end.map do |a|
          send("extract_#{a.type}_name", a)
        end
      end
    end

    # A method defines as a :def AST node.
    class InstanceMethodParseNode < MethodParseNode
      def name
        node.children[0].to_s
      end

      def class_name
        enclosing_names.join('::')
      end

      # An instance method defined in an sclass is a static method.
      def static?
        result = ancestors[-1].type == :sclass ||
          (ancestors[-1].type == :begin && ancestors[-2] && ancestors[-2].type == :sclass)
        !!result
      end

      def public?
        preceding_send = preceding_sibling_nodes
                         .reverse
                         .select { |n| n.type == :send }
                         .find { |n| %i[public protected private].member?(n.children[1]) }
        preceding_send.nil? || preceding_send.children[1] == :public
      end
    end

    # A method defines as a :defs AST node.
    # For example:
    #
    # class Main
    #   def Main.main_func
    #  end
    # end
    class StaticMethodParseNode < MethodParseNode
      def name
        node.children[1].to_s
      end

      def class_name
        ancestor_names = enclosing_names
        ancestor_names.pop
        ancestor_names << node.children[0].children[1]
        ancestor_names.join('::')
      end

      def static?
        true
      end
    end

    def initialize(file_path)
      @file_path = file_path
    end

    def to_s
      "Inspect #{file_path.inspect}"
    end

    # Parse the contents of a file into a list of annotations.
    def parse
      parse_tree, comments = begin
        Parser::CurrentRuby.parse_with_comments(File.read(file_path))
      rescue Parser::SyntaxError, EncodingError
        warn "Unable to parse #{file_path.inspect}"
        warn $ERROR_INFO.message
        return []
      end

      nodes_by_line = {}
      annotations_by_ast_node = {}
      visit_methods = lambda do |node, ancestors|
        return unless node.respond_to?(:type)

        parse_node = ParseNode.from_node(node, file_path, ancestors)
        nodes_by_line[node.loc.line] = parse_node if parse_node

        ancestors << node
        node.children.each do |child|
          visit_methods.call(child, ancestors)
        end
        ancestors.pop
      end
      visit_methods.call(parse_tree, [])

      annotations = []

      comments.select { |c| c.text.index('@appmap') }.each do |c|
        c.text.split("\n").select { |l| l.index('@appmap') }.each do |annotation|
          tokens = annotation.split
          tokens.delete_if { |t| %w[# @appmap].member?(t) }
          attributes = tokens.inject({}) do |memo, token|
            key, value = token.split('=')
            memo.tap do |attrs|
              attrs[key.to_sym] = value
            end
          end

          parse_node = nodes_by_line[c.location.last_line + 1]
          if parse_node
            annotation = parse_node.to_annotation(attributes)
            annotations_by_ast_node[parse_node.node] = annotation
            if annotation
              if (enclosing_type_node = parse_node.enclosing_type_node) &&
                 (parent_annotation = annotations_by_ast_node[enclosing_type_node])
                parent_annotation.children << annotation
              else
                annotations << annotation
              end

              # At this point there's a parse_node and an associated annotation.
              # If the annotation is a class which has the option 'include=public_methods',
              # scan the rest of the class body for public methods and create annotations
              # for them.

              if parse_node.type == :class && annotation.include_option.member?('public_methods')
                begin_node = parse_node.node.children.find { |n| n.respond_to?(:type) && n.type == :begin }
                if begin_node
                  public_methods = begin_node
                                   .children
                                   .select { |n| n.respond_to?(:type) && n.type == :def }
                                   .map { |n| ParseNode.from_node(n, file_path, parse_node.ancestors + [ parse_node.node, begin_node ]) }
                                   .select(&:public?)
                  annotation.children += public_methods.map { |m| m.to_annotation([]) }.compact
                end
              end
            end
          else
            warn "No parse node found at #{file_path}:#{c.location.last_line + 1}"
          end
        end
      end

      annotations.delete_if { |a| !a.valid? }
      annotations
    end
  end
end

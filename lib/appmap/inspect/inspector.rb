module AppMap
  module Inspect
    # Inspector is an abstract class for extracting features from a Ruby program.
    class Inspector
      attr_reader :file_path, :parse_nodes, :comments

      def initialize(file_path, parse_nodes, comments)
        @file_path = file_path
        @parse_nodes = parse_nodes
        @comments = comments
      end
    end

    # ImplicitInspector extracts features from a Ruby program, creating a feature for each public class and method.
    class ImplicitInspector < Inspector
      def inspect_file
        features = []
        features_by_ast_node = {}
        parse_nodes.select(&:public?).each do |parse_node|
          feature = parse_node.to_feature({})
          features_by_ast_node[parse_node.node] = feature
          if feature
            if (enclosing_type_node = parse_node.enclosing_type_node) &&
               (parent_feature = features_by_ast_node[enclosing_type_node])
              parent_feature.add_child(feature)
            else
              features << feature
            end
          end
        end

        features.keep_if(&:valid?)
        features
      end
    end

    # ExplicitInspector extracts features from a Ruby program, requiring the use of @appmap annotations to mark each
    # relevant class and method.
    class ExplicitInspector < Inspector
      def inspect_file
        nodes_by_line = parse_nodes.each_with_object({}) { |node, h| h[node.node.loc.line] = node }

        features_by_ast_node = {}
        features = []

        comments.select { |c| c.text.index('@appmap') }.each do |c|
          c.text.split("\n").select { |l| l.index('@appmap') }.each do |feature|
            tokens = feature.split
            tokens.delete_if { |t| %w[# @appmap].member?(t) }
            attributes = tokens.inject({}) do |memo, token|
              key, value = token.split('=')
              memo.tap do |attrs|
                attrs[key.to_sym] = value
              end
            end

            parse_node = nodes_by_line[c.location.last_line + 1]
            if parse_node
              feature = parse_node.to_feature(attributes)
              features_by_ast_node[parse_node.node] = feature
              if feature
                if (enclosing_type_node = parse_node.enclosing_type_node) &&
                   (parent_feature = features_by_ast_node[enclosing_type_node])
                  parent_feature.add_child(feature)
                else
                  features << feature
                end

                # At this point there's a parse_node and an associated feature.
                # If the feature is a class which has the option 'include=public_methods',
                # scan the rest of the class body for public methods and create features
                # for them.

                if parse_node.type == :class && feature.include_option.member?('public_methods')
                  begin_node = parse_node.node.children.find { |n| n.respond_to?(:type) && n.type == :begin }
                  if begin_node
                    public_methods = begin_node
                                     .children
                                     .select { |n| n.respond_to?(:type) && n.type == :def }
                                     .map { |n| ParseNode.from_node(n, file_path, parse_node.ancestors + [ parse_node.node, begin_node ]) }
                                     .select(&:public?)
                    public_methods.map { |m| m.to_feature([]) }.compact.each do |f|
                      feature.add_child(f)
                    end
                  end
                end
              end
            else
              warn "No parse node found at #{file_path}:#{c.location.last_line + 1}"
            end
          end
        end

        features.keep_if(&:valid?)
        features
      end
    end
  end
end

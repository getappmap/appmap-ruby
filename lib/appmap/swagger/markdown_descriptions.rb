require 'active_support'
require 'active_support/core_ext'
require 'rdoc'
require 'reverse_markdown'

module AppMap
  module Swagger
    # Transform description fields into Markdown.
    class MarkdownDescriptions
      def initialize(swagger_yaml)
        @swagger_yaml = swagger_yaml
      end

      def converter
        method(:rdoc_to_markdown)
      end

      def perform
        to_markdown = lambda do |obj|
          return obj.each(&to_markdown) if obj.is_a?(Array)
          return unless obj.is_a?(Hash)

          description = obj['description']
          obj['description'] = converter.(description) if description

          obj.reject { |k,v| k == 'properties' }.each_value(&to_markdown)

          obj
        end

        to_markdown.(@swagger_yaml.deep_dup)
      end

      protected

      def rdoc_to_markdown(comment)
        # Strip tags
        comment = comment.split("\n").reject { |line| line =~ /^\s*@/ }.join("\n")
        converter = ::RDoc::Markup::ToHtml.new(::RDoc::Options.new)
        html = converter.convert(comment).strip
        ::ReverseMarkdown.convert(html).strip
      end
    end
  end
end

require 'active_support'
require 'active_support/core_ext'

module AppMap
  module Swagger
    # Transform description fields into Markdown.
    class MarkdownDescriptions
      def initialize(swagger_yaml)
        @swagger_yaml = swagger_yaml
      end

      def converter
        @converter ||= build_converter
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

      def build_converter
        load_gem = lambda do |gem_name|
          require gem_name
          true
        rescue NameError
          warn "'#{gem_name}' gem is not available. Descriptions cannot be converted from RDoc to Markdown."
          warn "To fix this, add the '#{gem_name}' gem to your Gemfile"
          false
        end

        return method(:rdoc_to_s) unless load_gem.('reverse_markdown') && load_gem.('rdoc')

        method(:rdoc_to_markdown)
      end

      def rdoc_to_s(comment)
        comment
      end

      def rdoc_to_markdown(comment)
        converter = ::RDoc::Markup::ToHtml.new(::RDoc::Options.new)
        html = converter.convert(comment).strip
        ::ReverseMarkdown.convert(html).strip
      end
    end
  end
end

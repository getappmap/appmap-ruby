module AppMap
  module Annotation
    KIND_MAP = {
      'cls' => 'class'
    }.freeze

    class << self
      def from_hash(hash)
        annotation = case hash['kind'].to_sym
        when :module
          Module.new
        when :class
          Cls.new
        when :method
          static = hash.delete('static')
          class_name = hash.delete('class_name')
          Method.new.tap do |e|
            e.static = static
            e.class_name = class_name
          end
        else
          raise "Unrecognized 'kind' #{kind.inspect}"
        end
        annotation.name = hash['name']
        annotation.location = hash['location']
        annotation.attributes = hash['attributes'] || {}
        annotation.children = (hash['children'] || []).map { |child| from_hash(child) }
        annotation
      end
    end

    Base = Struct.new(:name, :location, :attributes, :children) do
      # The 'include' attribute can indicate which elements of the parse subtree
      # to automatically include. For example: public_classes, public_modules,
      # public_methods.
      def include_option
        (attributes[:include] || '').split(',')
      end

      # yield each method to a block.
      def collect_methods(accumulator = [])
        accumulator.tap do |_|
          accumulator << self if is_a?(Method)
          children.each { |child| child.collect_methods(accumulator) }
        end
      end

      def valid?
        !name.blank? && !location.blank?
      end

      def to_json(*opts)
        to_h.to_json(*opts)
      end

      def to_h
        super.tap do |map|
          class_name = self.class.name.underscore.split('/')[-1]
          map[:kind] = KIND_MAP[class_name] || class_name
          map.delete(:children) if map[:children].empty?
          map.delete(:attributes) if map[:attributes].empty?
        end
      end
    end

    class Module < Base
    end

    class Cls < Base
    end

    class Method < Base
      attr_accessor :static, :class_name

      alias static? static

      # Static functions must have an enclosing class defined in order to be traced.
      def valid?
        super && (!static || !class_name.blank?)
      end

      def to_h
        super.merge(class_name: class_name, static: static?)
      end
    end
  end
end

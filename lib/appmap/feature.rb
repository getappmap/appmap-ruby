module AppMap
  # A Feature is a construct within the code that will be observed. Examples features include
  # modules, classes and methods.
  module Feature
    KIND_MAP = {
      'cls' => 'class'
    }.freeze

    class << self
      FEATURE_BUILDERS = {
        module: ->(_) { Module.new },
        class: ->(_) { Cls.new },
        method: lambda do |hash|
                  static = hash.delete('static')
                  class_name = hash.delete('class_name')
                  Method.new.tap do |e|
                    e.static = static
                    e.class_name = class_name
                  end
                end
      }.freeze

      # Deserialize a feature from a Hash. The Hash is typically a deserialized JSON dump of the feature.
      def from_hash(hash)
        builder = FEATURE_BUILDERS[hash['kind'].to_sym]
        raise "Unrecognized kind of feature: #{kind.inspect}" unless builder
        feature = builder.call(hash)
        feature.name = hash['name']
        feature.location = hash['location']
        feature.attributes = hash['attributes'] || {}
        feature.children = (hash['children'] || []).map { |child| from_hash(child) }
        feature
      end
    end

    # Base is an abstract base class for features.
    Base = Struct.new(:name, :location, :attributes, :children) do
      # The 'include' attribute can indicate which elements of the parse subtree
      # to automatically add as features. For example: public_classes, public_modules,
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

    # Module is a feature which represents a code module. A module is different from a class in that
    # it doesn't typically hold or contain any data; it's just a namespace for other features.
    class Module < Base
    end

    # Cls is a feature which represents a code class. A class defines a namespace which contains other
    # features (such as member classes and methods), and it also usually encapsulates some data on which
    # the member features operate.
    class Cls < Base
    end

    # Method is a feature which represents a code method. It can be an instance method or static (aka 'class')
    # method. Instance methods operate on the instance data of the class on which they are defined. Static
    # methods are used to perform operations which don't have want or need of instance data.
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

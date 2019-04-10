module AppMap
  # A Feature is a construct within the code that will be observed. Examples features include
  # modules, classes and functions.
  module Feature
    TYPE_MAP = {
      'cls' => 'class'
    }.freeze

    class << self
      FEATURE_BUILDERS = {
        module: ->(_) { Module.new },
        class: ->(_) { Cls.new },
        function: lambda do |hash|
                    static = hash.delete('static')
                    class_name = hash.delete('class_name')
                    Function.new.tap do |e|
                      e.static = static
                      e.class_name = class_name
                    end
                  end
      }.freeze

      # Deserialize a feature from a Hash. The Hash is typically a deserialized JSON dump of the feature.
      def from_hash(hash)
        builder = FEATURE_BUILDERS[hash['type'].to_sym]
        raise "Unrecognized type of feature: #{type.inspect}" unless builder
        feature = builder.call(hash)
        feature.name = hash['name']
        feature.location = hash['location']
        feature.attributes = hash['attributes'] || {}
        feature.children = (hash['children'] || []).map { |child| from_hash(child) }
        feature
      end
    end

    FeatureStruct = Struct.new(:name, :location, :attributes)

    # Base is an abstract base class for features.
    class Base < FeatureStruct
      class << self
        def expand_path(location)
          path, lineno = location.split(':')
          [ File.absolute_path(path), lineno ].compact.join(':')
        end
      end

      attr_reader :parent, :children

      def initialize(name, location, attributes)
        super(name, self.class.expand_path(location), attributes)

        @parent = nil
        @children = []
      end

      def remove_child(child)
        # TODO: Encountered this indexing appland with active_dispatch
        children.delete(child) or warn "Unable to remove #{name.inspect} from parent" # or raise "No such child : #{child}"
        child.instance_variable_set('@parent', nil)
      end

      def add_child(child)
        @children << child
        child.instance_variable_set('@parent', self)
      end

      # Gets an array containing the type names which enclose this feature.
      def enclosing_type_name
        @enclosing_type_name ||= [].tap do |names|
          p = self
          while (p = p.parent) && p.type?
            names << p.name
          end
        end.reverse
      end

      # true iff this feature has an enclosing type. An example of when this is false: when
      # the parent of the feature is not a type (e.g. it's a location).
      def enclosing_type_name?
        !enclosing_type_name.empty?
      end

      # The 'include' attribute can indicate which elements of the parse subtree
      # to automatically add as features. For example: public_classes, public_modules,
      # public_methods.
      def include_option
        (attributes[:include] || '').split(',')
      end

      # yield each function to a block.
      def collect_functions(accumulator = [])
        accumulator.tap do |_|
          accumulator << self if is_a?(Function)
          children.each { |child| child.collect_functions(accumulator) }
        end
      end

      def type?
        false
      end

      def valid?
        !name.blank? && !location.blank?
      end

      def to_json(*opts)
        to_h.to_json(*opts)
      end

      def to_h
        super.tap do |map|
          map.delete(:parent)
          class_name = self.class.name.underscore.split('/')[-1]
          map[:type] = TYPE_MAP[class_name] || class_name
          map[:children] = @children.map(&:to_h) unless @children.empty?
          map.delete(:attributes) if map[:attributes].empty?
        end
      end

      # Determines if this feature should be dropped from the feature tree.
      # A feature is dropped from the feature tree if it doesn't add useful information for the user.
      # Performing this operation removes feature nodes that don't add anything useful to the user.
      # For example, empty classes.
      def prune(parent = nil)
        should_prune = prune? && !parent.nil?
        parent = self unless should_prune
        children.dup.each do |child|
          child.prune(parent)
        end

        # Perform the prune in post-fix traversal order, otherwise the
        # features will get confused about whether they should prune or not.
        if should_prune
          parent.remove_child(self)
          children.each do |child|
            parent.add_child(child)
          end
        end
      end

      # Determines if this feature should be re-parented as a child of a different feature.
      #
      # A feature is re-parented if the enclosing type of the feature has already been defined in the tree.
      #
      # @param parent the parent of this feature in the compacted tree.
      def reparent(parent = nil, features_by_type = {})
        # Determine if the enclosing type of the feature is defined.
        # Generally, it should be.

        existing_enclosing_type = features_by_type[enclosing_type_name] if enclosing_type_name?
        if existing_enclosing_type
          parent = existing_enclosing_type
        end

        # Determine if this feature is a type which is already defined.
        type_exists = true if type? && features_by_type.key?(type_name)

        # If this feature is a type that's already defined, skip over it and
        # add the children to the existing feature. Otherwise, clone this feature
        # under the parent and use the cloned object as the parent of the compacted 
        # children.
        if type_exists
          features_by_type[type_name]
        else
          clone.tap do |f|
            parent.add_child(f) if parent
            features_by_type[type_name] = f if type?
          end
        end.tap do |updated_parent|
          children.each do |child|
            child.reparent(updated_parent, features_by_type)
          end
        end
      end

      def prune?
        false
      end

      protected

      def clone
        self.class.new(name, location, attributes)
      end

      def child_classes
        children.select { |c| c.is_a?(Cls) }
      end

      def child_nonclasses
        children.reject { |c| c.is_a?(Cls) }
      end
    end

    # Package is a feature which represents the directory containing code.
    class Package < Base
      # prune a package if it's empty, or if it contains anything but packages.
      def prune?
        children.empty? || children.any? { |c| !c.is_a?(Package) }
      end
    end

    # Cls is a feature which represents a code class. A class defines a namespace which contains other
    # features (such as member classes and functions), and it also usually encapsulates some data on which
    # the member features operate.
    class Cls < Base
      # prune a class if it's empty.
      def prune?
        children.empty?
      end

      def type?
        true
      end

      # Gets the type name of this class as an array.
      def type_name
        @type_name ||= enclosing_type_name + [ name ]
      end
    end

    # Function is a feature which represents a code function. It can be an instance function or static (aka 'class')
    # function. Instance functions operate on the instance data of the class on which they are defined. Static
    # functions are used to perform operations which don't have want or need of instance data.
    class Function < Base
      attr_accessor :static, :class_name

      alias static? static
      def instance?
        !static?
      end

      # Static functions must have an enclosing class defined in order to be traced.
      def valid?
        super && (instance? || !class_name.blank?)
      end

      def to_h
        super.tap do |h|
          # Suppress the class name when it can be inferred from the enclosing type.
          h[:class_name] = class_name if class_name && class_name != enclosing_type_name.join('::')
          h[:static] = static?
        end
      end

      protected

      def clone
        super.tap do |obj|
          obj.static = static
          obj.class_name = class_name
        end
      end
    end
  end
end

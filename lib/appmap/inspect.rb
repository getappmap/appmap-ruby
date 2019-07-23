require 'appmap/inspect/inspector'
require 'appmap/inspect/parser'

module AppMap
  # Inspect identifies features from a Ruby file.
  module Inspect
    class << self
      # Detect features from a source code repository. The manner in which the features are detected in the
      # code is defined and tuned by a path configuration object. The path configuration tells the
      # feature detector what it should do when it encounters code that may be a "sub-feature",
      # for example a public instance method of a class.
      #
      # rubocop:disable Metrics/AbcSize
      # rubocop:disable Metrics/MethodLength
      # @appmap
      def detect_features(config_spec)
        child_features = -> { config_spec.children.map(&Inspect.method(:detect_features)).flatten.compact }
        parse_file = -> { inspect_file(config_spec.mode, file_path: config_spec.path) }

        feature_builders = Hash.new { |_, key| raise "Unable to build features for #{key.inspect}" }
        feature_builders[AppMap::Config::Directory] = child_features
        feature_builders[AppMap::Config::File] = parse_file
        feature_builders[AppMap::Config::PackageDir] = lambda {
          AppMap::Feature::Package.new(config_spec.package_name, config_spec.path, {}).tap do |package|
            child_features.call.each do |child|
              package.add_child(child)
            end
          end
        }
        feature_builders[AppMap::Config::NamedFunction] = lambda {
          # Loads named functions by finding the requested gem, finding the file within the gem,
          # parsing that file, and then inspecting the module/class scope for the requested method.
          # We can't 'require' the specified code, because if we do that, it can change the
          # behavior of the program.

          gem = Gem.loaded_specs[config_spec.gem_name]
          return [] unless gem

          gem_dir = gem.gem_dir
          file_path = File.join(gem_dir, config_spec.file_path)

          parse_nodes, comments = Parser.new(file_path: file_path).parse
          features = ImplicitInspector.new(file_path, parse_nodes, comments).inspect_file

          class_names = config_spec.class_names.dup
          until class_names.empty?
            class_name = class_names.shift
            feature = features.find { |f| f.to_h[:type] == 'class' && f.name == class_name }
            raise "#{class_name.inspect} not found" unless feature

            features = feature.children
          end

          function = features.find { |f| f.to_h[:type] == 'function' && f.name == config_spec.method_name && f.static == config_spec.static }

          # If the configuration specifier has an id, use it as the handler id.
          # This is how we can associate custom handler logic with the named function.
          function.handler_id = config_spec.id.to_s if config_spec.id

          AppMap::Feature::Package.new(config_spec.gem_name, "#{gem_dir}:0", {}).tap do |pkg|
            parent = pkg
            class_names = config_spec.class_names.dup
            until class_names.empty?
              class_name = class_names.shift
              cls = AppMap::Feature::Cls.new(class_name, "#{gem_dir}:0", {})
              parent.children << cls
              parent = cls
            end
            parent.children << function
          end
        }

        feature_builders[config_spec.class].call
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # Inspect a specific file for features.
      #
      # @appmap
      def inspect_file(strategy, file_path: nil)
        parse_nodes, comments = Parser.new(file_path: file_path).parse
        inspector_class = {
          implicit: ImplicitInspector,
          explicit: ExplicitInspector
        }[strategy] or raise "Invalid strategy : #{strategy.inspect}"
        inspector_class.new(file_path, parse_nodes, comments).inspect_file
      end
    end
  end
end

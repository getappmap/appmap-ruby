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
      def detect_features(path_config)
        child_features = -> { path_config.children.map(&Inspect.method(:detect_features)).flatten.compact }
        parse_file = -> { inspect_file(path_config.mode, file_path: path_config.path) }

        feature_builders = Hash.new { |_, key| raise "Unable to build features for #{key.inspect}" }
        feature_builders[AppMap::Config::Directory] = child_features
        feature_builders[AppMap::Config::File] = parse_file
        feature_builders[AppMap::Config::PackageDir] = lambda {
          AppMap::Feature::Package.new(path_config.package_name, path_config.path, {}).tap do |package|
            child_features.call.each do |child|
              package.add_child(child)
            end
          end
        }
        feature_builders[AppMap::Config::Dependency] = lambda {
          gem = Gem.loaded_specs[path_config.gem_name]
          return [] unless gem

          gem_dir = gem.gem_dir
          file_path = File.join(gem_dir, path_config.file_path)

          # Inspect the file to detect all the classes and functions.
          # Then search for the one that we expect to be there.
          # This way, we don't have to 'require'; because if we do that, it can change the 
          # behavior of the program.
          parse_nodes, comments = Parser.new(file_path: file_path).parse
          features = ImplicitInspector.new(file_path, parse_nodes, comments).inspect_file

          class_names = path_config.class_names.dup
          until class_names.empty?
            class_name = class_names.shift
            feature = features.find { |f| f.to_h[:type] == 'class' && f.name == class_name }
            raise "#{class_name.inspect} not found" unless feature

            features = feature.children
          end

          function = features.find { |f| f.to_h[:type] == 'function' && f.name == path_config.method_name && f.static == path_config.static }
          function.handler_id = path_config.id.to_s

          AppMap::Feature::Package.new(path_config.gem_name, "#{gem_dir}:0", {}).tap do |pkg|
            parent = pkg
            class_names = path_config.class_names.dup
            until class_names.empty?
              class_name = class_names.shift
              cls = AppMap::Feature::Cls.new(class_name, "#{gem_dir}:0", {})
              parent.children << cls
              parent = cls
            end
            parent.children << function
          end
        }

        feature_builders[path_config.class].call
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

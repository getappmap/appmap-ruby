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

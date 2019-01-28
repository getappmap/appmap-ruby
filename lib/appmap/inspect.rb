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
        parse_file = -> { inspect_file(path_config.mode, path_config.path) }

        feature_builders = {
          AppMap::Config::Directory => child_features,
          AppMap::Config::File => parse_file,
          AppMap::Config::ModuleDir => lambda {
            AppMap::Feature::Module.new(path_config.module_name, path_config.path, {}, child_features.call)
          },
          AppMap::Config::Rails => child_features
        }

        builder = feature_builders[path_config.class]
        raise "Unable to build features for #{path_config.class}" unless builder
        builder.call
      end
      # rubocop:enable Metrics/AbcSize
      # rubocop:enable Metrics/MethodLength

      # Inspect a specific file for features.
      #
      # @appmap
      def inspect_file(strategy, file_path)
        parse_nodes, comments = Parser.new(file_path).parse
        inspector_class = \
          case strategy
          when :implicit
            ImplicitInspector
          when :explicit
            ExplicitInspector
          else
            raise "Invalid strategy : #{strategy.inspect}"
          end
        inspector_class.new(file_path, parse_nodes, comments).inspect_file
      end
    end
  end
end

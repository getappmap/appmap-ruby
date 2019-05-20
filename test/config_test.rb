require 'test_helper'
require 'appmap/config'
require 'appmap/inspect'

class ConfigTest < Minitest::Test
  include FixtureFile

  def test_explicit_module_path_naming
    config = AppMap::Config::PackageDir.new(INSPECT_PACKAGE_FIXTURE_DIR, 'inspect_package').tap do |c|
      c.mode = :explicit
    end
    config.exclude = [ 'inspect_package/module_a/ignore_module_c' ]
    feature = AppMap::Inspect.detect_features(config)

    assert_equal %w[inspect_package module_a module_b], feature_names(feature)
  end

  def test_implicit_module_path_naming
    config = AppMap::Config::PackageDir.new(INSPECT_PACKAGE_FIXTURE_DIR, 'inspect_package')
    config.exclude = [ 'inspect_package/module_a/ignore_module_c' ]
    feature = AppMap::Inspect.detect_features(config)

    assert_equal %w[inspect_package module_a module_b A B Main], feature_names(feature)
  end

  def test_ignore_non_ruby_file
    config = AppMap::Config::PackageDir.new(File.join(FIXTURE_DIR, 'ignore_non_ruby_file'), 'ignore_non_ruby_file')
    feature = AppMap::Inspect.detect_features(config)
    assert_equal %w[ignore_non_ruby_file Cls], feature_names(feature)
  end

  def test_inspect_multiple_subdirs
    config_yaml = <<-YAML
    module_a:
      type: package

    module_b:
      type: package
    YAML

    require 'yaml'
    config = AppMap::Config.load YAML.safe_load(config_yaml)
    features = Dir.chdir File.join(FIXTURE_DIR, 'inspect_multiple_subdirs') do
      config.map(&AppMap::Inspect.method(:detect_features))
    end
    features = features.map(&:reparent)
    assert_equal %w[module_a ModuleA ClassA module_b ModuleB ClassC ClassB], features.map(&method(:feature_names)).flatten
  end

  def test_active_record_like
    config_yaml = <<-YAML
    .:
      type: package
      name: ROOT
    YAML

    require 'yaml'
    config = AppMap::Config.load YAML.safe_load(config_yaml)
    features = Dir.chdir File.join(FIXTURE_DIR, 'active_record_like') do
      config.map(&AppMap::Inspect.method(:detect_features))
    end
    features = features.map(&:reparent)

    assert_equal <<-FEATURES.strip, JSON.pretty_generate(features)
[
  {
    "name": "ROOT",
    "location": ".",
    "type": "package",
    "children": [
      {
        "name": "ActiveRecord",
        "location": "./active_record.rb:1",
        "type": "class",
        "children": [
          {
            "name": "Aggregations",
            "location": "./active_record/aggregations.rb:2",
            "type": "class"
          },
          {
            "name": "Associations",
            "location": "./active_record/association.rb:2",
            "type": "class",
            "children": [
              {
                "name": "JoinDependency",
                "location": "./active_record/associations/join_dependency.rb:3",
                "type": "class",
                "children": [
                  {
                    "name": "JoinBase",
                    "location": "./active_record/associations/join_dependency/join_base.rb:4",
                    "type": "class"
                  },
                  {
                    "name": "JoinPart",
                    "location": "./active_record/associations/join_dependency/join_part.rb:4",
                    "type": "class"
                  }
                ]
              }
            ]
          },
          {
            "name": "CAPS",
            "location": "./active_record/caps/caps.rb:2",
            "type": "class"
          }
        ]
      },
      {
        "name": "active_record",
        "location": "./active_record",
        "type": "package",
        "children": [
          {
            "name": "associations",
            "location": "./active_record/associations",
            "type": "package",
            "children": [
              {
                "name": "join_dependency",
                "location": "./active_record/associations/join_dependency",
                "type": "package"
              }
            ]
          },
          {
            "name": "caps",
            "location": "./active_record/caps",
            "type": "package"
          }
        ]
      }
    ]
  }
]
    FEATURES
  end

  def feature_names(feature, names = [])
    names.tap do |_|
      names << feature.name
      feature.children.each { |child| feature_names(child, names) }
    end
  end
end

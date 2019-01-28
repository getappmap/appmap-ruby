require 'test_helper'
require 'appmap/config'
require 'appmap/inspect'

class ConfigTest < Minitest::Test
  include FixtureFile

  def test_explicit_module_path_naming
    config = AppMap::Config::ModuleDir.new(INSPECT_MODULE_FIXTURE_DIR, 'inspect_module').tap do |c|
      c.mode = :explicit
    end
    config.exclude = [ 'inspect_module/module_a/ignore_module_c' ]
    feature = AppMap::Inspect.detect_features(config)

    assert_equal %w[inspect_module module_a module_b], feature_names(feature)
  end

  def test_implicit_module_path_naming
    config = AppMap::Config::ModuleDir.new(INSPECT_MODULE_FIXTURE_DIR, 'inspect_module')
    config.exclude = [ 'inspect_module/module_a/ignore_module_c' ]
    feature = AppMap::Inspect.detect_features(config)

    assert_equal %w[inspect_module module_a module_b Main], feature_names(feature)
  end

  def test_ignore_non_ruby_file
    config = AppMap::Config::ModuleDir.new(File.join(FIXTURE_DIR, 'ignore_non_ruby_file'), 'ignore_non_ruby_file')
    feature = AppMap::Inspect.detect_features(config)
    assert_equal %w[ignore_non_ruby_file Cls], feature_names(feature)
  end

  def test_inspect_multiple_subdirs
    config_yaml = <<-YAML
    module_a:
      type: module
      module_name: module_a
  
    module_b:
      type: module
      module_name: module_b
    YAML

    require 'yaml'
    config = AppMap::Config.load YAML.safe_load(config_yaml)
    features = Dir.chdir File.join(FIXTURE_DIR, 'inspect_multiple_subdirs') do
      config.map(&AppMap::Inspect.method(:detect_features))
    end
    assert_equal %w[module_a ClassA module_b ClassB], features.map(&method(:feature_names)).flatten
  end

  def feature_names(feature, names = [])
    names.tap do |_|
      names << feature.name
      feature.children.each { |child| feature_names(child, names) }
    end
  end
end

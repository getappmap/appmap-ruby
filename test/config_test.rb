require 'test_helper'
require 'appmap/config'
require 'appmap/inspector'

class ConfigTest < Minitest::Test
  include FixtureFile

  def test_module_path_naming
    config = AppMap::Config::ModuleDir.new(INSPECT_MODULE_FIXTURE_DIR, 'inspect_module')
    config.exclude = [ 'inspect_module/module_a/ignore_module_c' ]
    annotation = AppMap::Inspector.detect_annotations(config)

    assert_equal %w[inspect_module module_a module_b], annotation_names(annotation)
  end

  def test_ignore_non_ruby_file
    config = AppMap::Config::ModuleDir.new(File.join(FIXTURE_DIR, 'ignore_non_ruby_file'), 'ignore_non_ruby_file')
    annotation = AppMap::Inspector.detect_annotations(config)
    assert_equal %w[ignore_non_ruby_file Cls], annotation_names(annotation)
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
    annotations = Dir.chdir File.join(FIXTURE_DIR, 'inspect_multiple_subdirs') do
      config.map(&AppMap::Inspector.method(:detect_annotations))
    end
    assert_equal %w[module_a ClassA module_b ClassB], annotations.map(&method(:annotation_names)).flatten
  end

  def annotation_names(annotation, names = [])
    names.tap do |_|
      names << annotation.name
      annotation.children.each { |child| annotation_names(child, names) }
    end
  end
end

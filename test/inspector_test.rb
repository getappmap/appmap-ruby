require 'test_helper'
require 'appmap/inspector'

class InspectorTest < Minitest::Test
  include FixtureFile

  def test_toplevel_class
    assert_fixture_annotations 'toplevel_class.rb'
  end

  def test_defs_static_function
    assert_fixture_annotations 'defs_static_function.rb'
  end

  def test_sclass_static_function
    assert_fixture_annotations 'sclass_static_function.rb'
  end

  def test_toplevel_function
    assert_fixture_annotations 'toplevel_function.rb'
  end

  def test_function_within_class
    assert_fixture_annotations 'function_within_class.rb'
  end

  def test_include_public_methods
    assert_fixture_annotations 'include_public_methods.rb'
  end
end

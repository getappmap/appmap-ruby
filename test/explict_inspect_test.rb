require 'test_helper'

class ExplicitInspectTest < Minitest::Test
  include FixtureFile

  def test_toplevel_class
    assert_fixture_features :explicit, 'toplevel_class.rb'
  end

  def test_defs_static_function
    assert_fixture_features :explicit, 'defs_static_function.rb'
  end

  def test_sclass_static_function
    assert_fixture_features :explicit, 'sclass_static_function.rb'
  end

  def test_toplevel_function
    assert_fixture_features :explicit, 'toplevel_function.rb'
  end

  def test_function_within_class
    assert_fixture_features :explicit, 'function_within_class.rb'
  end

  def test_include_public_methods
    assert_fixture_features :explicit, 'include_public_methods.rb'
  end
end

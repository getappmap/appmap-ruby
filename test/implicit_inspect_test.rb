require 'test_helper'

class ImplicitInspectTest < Minitest::Test
  include FixtureFile

  def test_toplevel_class
    assert_fixture_features :implicit, 'toplevel_class.rb'
  end

  def test_defs_static_function
    assert_fixture_features :implicit, 'defs_static_function.rb'
  end

  def test_sclass_static_function
    assert_fixture_features :implicit, 'sclass_static_function.rb'
  end

  def test_toplevel_function
    assert_fixture_features :implicit, 'toplevel_function.rb'
  end

  def test_function_within_class
    assert_fixture_features :implicit, 'function_within_class.rb'
  end

  def test_include_public_methods
    assert_fixture_features :implicit, 'include_public_methods.rb'
  end
end

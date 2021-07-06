# minitest_calc_test_unit_format_spec.rb

require "minitest/autorun"

class FunctionalCalcTest < Minitest::Test
  def test_add
    puts 'functional'
    assert_equal 2 + 2, 4
  end
end
# minitest_calc_test_unit_format_spec.rb

require "minitest/autorun"

class IntegrationCalcTest < Minitest::Test
  class CalcTest < Minitest::Test
    def test_add
      puts 'integration'
      assert_equal 2 + 2, 4
    end
  end
end
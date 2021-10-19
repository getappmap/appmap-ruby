$LOAD_PATH.unshift File.expand_path('../lib', __dir__)

require 'minitest/autorun'

require 'appmap'
require 'appmap/minitest' if ENV['APPMAP_AUTOREQUIRE'] == 'false'

require 'sheep'
require 'mocha/minitest'

class SheepTest < Minitest::Test
  def test_sheep
    sheep = mock('sheep')
    sheep.responds_like(Sheep.new)
    sheep.expects(:baa).returns('baa')
    sheep.baa
  end
end

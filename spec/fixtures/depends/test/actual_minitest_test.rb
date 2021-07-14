class ActualMinitestTest < Minitest::Test
  def test_object_to_s
    expect(subject.to_s).to be_instance_of(String)
  end
end

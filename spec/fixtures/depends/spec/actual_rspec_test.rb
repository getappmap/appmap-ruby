# This test has actual behavior because it's used to test the spec runner

describe Object do
  it 'to_s returns a representation of the object' do
    expect(subject.to_s).to be_instance_of(String)
  end
end
require 'rails_helper'

describe User do
  # TODO: appmap/rspec doesn't handle shared_examples_for 100% correctly yet.
  # In my tests, only one of these two tests will be emitted as an appmap.
  shared_examples_for 'creates the user' do |username|
    let(:login) { username }
    let(:user) { User.new(login: login) }
    it "creates #{username.inspect}" do
      expect(user.save(raise_on_failure: true)).to be_truthy
    end
  end

  describe 'creation' do
    # So, instead of shared_examples_for, let's go with a simple method
    # containing the assertions. The method can be called from within an example.
    def save_and_verify
      expect(user.save(raise_on_failure: true)).to be_truthy
    end

    context do
      let(:login) { 'charles' }
      let(:user) { User.new(login: login) }
      it "creates 'charles'" do
        save_and_verify
      end
    end
  end
end

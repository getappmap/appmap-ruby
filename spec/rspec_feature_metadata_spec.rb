require 'rails_spec_helper'

describe 'RSpec feature and feature group metadata' do
  before(:all) { @fixture_dir = 'spec/fixtures/rails_users_app' }
  include_examples 'Rails app pg database'
  
  around(:each) do |example|
    FileUtils.rm_rf tmpdir
    FileUtils.mkdir_p tmpdir
    cmd = "docker-compose run --rm -e APPMAP=true -v #{File.absolute_path(tmpdir).shellescape}:/app/tmp app ./bin/rspec spec/models/user_spec.rb"
    system cmd, chdir: @fixture_dir or raise 'Failed to run rails_users_app container'

    example.run
  end

  let(:tmpdir) { 'tmp/spec/RSpec feature and feature group metadata' }
  let(:appmap_json) { File.join(tmpdir, %(appmap/rspec/User_creation_creates_charles.json)) }

  describe do
    it 'are recorded in the appmap' do
      expect(File).to exist(appmap_json)
      appmap = JSON.parse(File.read(appmap_json)).to_yaml

      expect(appmap).to include(<<-METADATA.strip)
  feature: Create a user
  feature_group: User
      METADATA
    end
  end
end

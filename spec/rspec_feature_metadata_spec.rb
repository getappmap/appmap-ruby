# frozen_string_literal: true

require 'rails_spec_helper'

describe 'RSpec feature and feature group metadata' do
  include_examples 'Rails app pg database', 'spec/fixtures/rails5_users_app' do
    around(:each) do |example|
      FileUtils.rm_rf tmpdir
      FileUtils.mkdir_p tmpdir
      cmd = "docker-compose run --rm -e APPMAP=true -v #{File.absolute_path(tmpdir).shellescape}:/app/tmp app ./bin/rspec spec/models/user_spec.rb"
      run_cmd cmd, chdir: fixture_dir

      example.run
    end

    let(:tmpdir) { 'tmp/spec/RSpec feature and feature group metadata' }
    let(:appmap_json) { File.join(tmpdir, %(appmap/rspec/User_creation_creates_charles.appmap.json)) }

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
end

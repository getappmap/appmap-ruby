require "rails_spec_helper"

describe "around recording", order: :defined do
  include_context "rails app", "7"

  unless testing_ruby_2?
    it "creates a recording of a method labeled job.perform" do
      FileUtils.rm_rf "spec/fixtures/rails7_users_app/tmp/appmap/requests"

      app.prepare_db
      stdout, stderr, exit_code = app.capture_cmd \
        "bundle exec rake count_users",
        "RAILS_ENV" => "development"

      warn stderr if exit_code != 0
      warn stdout if exit_code != 0

      user_count = stdout.strip
      expect(user_count).to eq("User count: 0")
      appmaps_files = Dir.glob("spec/fixtures/rails7_users_app/tmp/appmap/requests/**/*.appmap.json")
      expect(appmaps_files.count).to eq(1)
      appmap_file = appmaps_files.first
      expect(appmap_file).to match(/\d+_perform_now_\d+.appmap\.json\z/)
      appmap = JSON.parse(File.read(appmap_file))
      metadata = appmap["metadata"]
      expect(metadata["recorder"]).to eq(
        "name" => "command",
        "type" => "requests"
      )
    end
  end
end

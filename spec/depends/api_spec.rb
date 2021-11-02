require_relative './spec_helper'
require 'appmap/depends/api'

module AppMap
  module Depends
    module APISpec
      class << self
        def minitest_environment_method
          AppMap::Depends.test_env
        end

        def rspec_environment_method
          AppMap::Depends.test_env
        end

        def minitest_test_command(test_files)
          "time bundle exec ruby -rminitest -Itest #{test_files}"
        end

        alias minitest_test_command_method minitest_test_command

        def rspec_test_command_method(test_files)
          "time bundle exec rspec #{test_files}"
        end

        def rspec_select_tests_method(test_files)
          AppMap::Depends.select_rspec_tests(test_files)
        end

        def minitest_select_tests_method(test_files)
          AppMap::Depends.select_minitest_tests(test_files)
        end
      end
    end
  end
end 

describe 'Depends API' do
  let(:api) { AppMap::Depends::API.new(ENV['DEBUG'] == 'true') }
  let(:fixture_dir) { DEPENDS_TEST_DIR }

  describe '.modified' do
    it 'is empty by default' do
      test_list = api.modified(appmap_dir: DEPENDS_TEST_DIR, base_dir: DEPENDS_BASE_DIR)
      expect(test_list).to be_empty
    end

    it 'detects modification of a dependent file' do
      FileUtils.touch 'spec/fixtures/depends/app/models/user.rb'
      test_list = api.modified(appmap_dir: DEPENDS_TEST_DIR, base_dir: DEPENDS_BASE_DIR)
      expect(test_list.to_a).to eq(%w[spec/fixtures/depends/spec/user_spec.rb])
    end
  end

  describe '.inspect_test_files' do
    it 'reports metadata, added, removed, changed, failed' do
      test_report = api.inspect_test_files(appmap_dir: DEPENDS_TEST_DIR, test_file_patterns: %w[spec/fixtures/depends/spec/*_spec.rb])
      expect(test_report.metadata_files.sort).to eq(%w[spec/fixtures/depends/revoke_api_key/metadata.json spec/fixtures/depends/user_page_scenario/metadata.json])
      expect(test_report.added).to be_empty
      expect(test_report.removed).to be_empty
      expect(test_report.changed).to be_empty
      expect(test_report.failed.to_a).to eq(%w[spec/fixtures/depends/spec/user_spec.rb])
    end
    it 'detects an added test' do
      FileUtils.touch 'spec/tmp/new_spec.rb'
      test_report = api.inspect_test_files(appmap_dir: DEPENDS_TEST_DIR, test_file_patterns: %w[spec/fixtures/depends/spec/*_spec.rb spec/tmp/*_spec.rb])
      expect(test_report.added.to_a).to eq(%w[spec/tmp/new_spec.rb])
    end
    it 'detects a removed test' do
      FileUtils.mv 'spec/fixtures/depends/spec/user_spec.rb', 'spec/tmp/'
      begin
        test_report = api.inspect_test_files(appmap_dir: DEPENDS_TEST_DIR, test_file_patterns: %w[spec/fixtures/depends/spec/*_spec.rb spec/tmp/*_spec.rb])
        expect(test_report.removed.to_a).to eq(%w[spec/fixtures/depends/spec/user_spec.rb])
      ensure
        FileUtils.mv 'spec/tmp/user_spec.rb', 'spec/fixtures/depends/spec/'
      end
    end
    it 'detects a changed test' do
      FileUtils.touch 'spec/fixtures/depends/spec/user_spec.rb'
      test_report = api.inspect_test_files(appmap_dir: DEPENDS_TEST_DIR, test_file_patterns: %w[spec/fixtures/depends/spec/*_spec.rb])
      expect(test_report.changed.to_a).to eq(%w[spec/fixtures/depends/spec/user_spec.rb])
    end
    it 'removes AppMaps whose source file has been removed' do
      appmap = JSON.parse(File.read('spec/fixtures/depends/revoke_api_key.appmap.json'))
      appmap['metadata']['source_location'] = 'spec/tmp/new_spec.rb'
      new_spec_file = 'spec/fixtures/depends/revoke_api_key_2.appmap.json'
      File.write new_spec_file, JSON.pretty_generate(appmap)

      begin
        update_appmap_index
        test_report = api.inspect_test_files(appmap_dir: DEPENDS_TEST_DIR, test_file_patterns: %w[spec/fixtures/depends/spec/*_spec.rb])
        expect(test_report.removed.to_a).to eq(%w[spec/tmp/new_spec.rb])

        test_report.clean_appmaps

        expect(File.exist?(new_spec_file)).to be_falsey
      ensure
        FileUtils.rm_f new_spec_file if File.exist?(new_spec_file)
        FileUtils.rm_rf new_spec_file.split('.')[0]
      end
    end
  end

  describe '.run_tests' do
    def run_tests
      Dir.chdir 'spec/fixtures/depends' do
        api.run_tests([ 'spec/actual_rspec_test.rb', 'test/actual_minitest_test.rb' ], appmap_dir: Pathname.new('.').expand_path.to_s)
      end
    end

    describe 'smoke test' do
      around do |test|
        @minitest_test_command_method = AppMap.configuration.depends_config.minitest_test_command_method
        AppMap.configuration.depends_config.minitest_test_command_method = 'AppMap::Depends::APISpec.minitest_test_command'
  
        test.call
      ensure
        AppMap.configuration.depends_config.minitest_test_command_method = @minitest_test_command
      end
  
      it 'passes a smoke test' do
        run_tests
      end
    end

    describe 'configuration settings' do
      it 'can all be modified' do
        defaults = {}

        %i[rspec minitest].each do |framework|
          %i[environment_method select_tests_method test_command_method].each do |setting|
            full_setting = [ framework, setting ].join('_').to_sym
            defaults[full_setting] = AppMap.configuration.depends_config.send(full_setting)
            AppMap.configuration.depends_config.send("#{full_setting}=", "AppMap::Depends::APISpec.#{full_setting}")
          end
        end

        run_tests
      ensure
        defaults.keys.each do |setting|
          AppMap.configuration.depends_config.send("#{setting}=", defaults[setting])
        end
      end
    end
  end

  describe '.remove_out_of_date_appmaps' do
    it 'is a nop in normal circumstances' do
      since = Time.now
      removed = api.remove_out_of_date_appmaps(since, appmap_dir: DEPENDS_TEST_DIR, base_dir: DEPENDS_BASE_DIR)
      expect(removed).to be_empty
    end

    it "removes an out-of-date AppMap that hasn't been brought up to date" do
      # This AppMap will be modified before the 'since' time
      appmap_path = "spec/fixtures/depends/user_page_scenario.appmap.json"
      appmap = File.read(appmap_path)

      sleep 0.01
      since = Time.now
      sleep 0.01

      # Touch the rest of the AppMaps so that they are modified after +since+
      Dir.glob('spec/fixtures/depends/*.appmap.json').each do |path|
        next if path == appmap_path
        FileUtils.touch path
      end

      sleep 0.01
      # Make the AppMaps out of date
      FileUtils.touch 'spec/fixtures/depends/app/models/user.rb'
      sleep 0.01

      begin
        # At this point, we would run tests to bring the AppMaps up to date
        # Then once the tests have finished, remove any AppMaps that weren't refreshed
        removed = api.remove_out_of_date_appmaps(since, appmap_dir: DEPENDS_TEST_DIR, base_dir: DEPENDS_BASE_DIR)
        expect(removed).to eq([ appmap_path.split('.')[0] ])  
      ensure
        File.write(appmap_path, appmap)        
      end
    end
  end
end

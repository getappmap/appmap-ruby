# frozen_string_literal: true

require 'open3'
require 'random-port'
require 'socket'

require 'spec_helper'
require 'active_support'
require 'active_support/core_ext'

def testing_ruby_2?
  RUBY_VERSION.split('.')[0].to_i == 2
end

# Rails5 doesn't work with Ruby 3.x, Rails 7 doesn't work with Ruby < 2.7.
def default_rails_versions
  if testing_ruby_2?
    if Gem::Requirement.create('>= 2.7') =~ Gem::Version.new(RUBY_VERSION)
      [ 5, 6, 7 ]
    else
      [ 5, 6 ]
    end
  else
    [ 6, 7 ]
  end
end

def rails_versions
  Array(ENV['RAILS_VERSIONS']&.split(',')&.map(&:to_i) || default_rails_versions)
end

class TestRailsApp
  def initialize(fixture_dir)
    @fixture_dir = fixture_dir
  end

  attr_reader :fixture_dir

  def run_cmd(cmd, env = {})
    run_process method(:system), cmd, env
  end

  def spawn_cmd(cmd, env = {})
    puts "Spawning `#{cmd}` in #{fixture_dir}..."
    run_process Process.method(:spawn), cmd, env
  end

  def capture_cmd(cmd, env = {})
    puts "Capturing `#{cmd}` in #{fixture_dir}..."
    run_process(Open3.method(:capture2), cmd, env).first
  end

  def database_name
    # This is used locally too, so make the name nice and unique.
    @database_name ||= "appland-rails-test-#{Random.new.bytes(8).unpack1('h*')}"
  end

  def bundle
    return if @bundled

    run_cmd 'bundle'
    @bundled = true
  end

  def prepare_db
    return if @db_prepared

    bundle
    run_cmd './bin/rake db:create db:schema:load'
    @db_prepared = true
    at_exit { drop_db }
  end

  def drop_db
    return unless @db_prepared

    run_cmd './bin/rake db:drop'
    @db_prepared = false
  end

  def tmpdir
    @tmpdir ||= File.join(fixture_dir, 'tmp')
  end

  def run_specs
    return if @specs_ran or use_existing_data?

    prepare_db
    FileUtils.rm_rf tmpdir
    run_cmd \
      './bin/rspec spec/controllers/users_controller_spec.rb spec/controllers/users_controller_api_spec.rb'
    @specs_ran = true
  end

  def self.for_fixture(fixture_dir)
    @apps ||= {}
    @apps[fixture_dir] ||= TestRailsApp.new fixture_dir
  end

  protected

  def run_process(method, cmd, env, options = {})
    Bundler.with_clean_env do
      method.call \
        env.merge('TEST_DATABASE' => database_name),
        cmd,
        options.merge(chdir: fixture_dir)
    end
  end
end

shared_context 'rails app' do |rails_major_version|
  include_context 'Rails app pg database', "spec/fixtures/rails#{rails_major_version}_users_app" unless use_existing_data?
end

shared_context 'Rails app pg database' do |dir|
  before(:all) { @app = TestRailsApp.for_fixture dir }
  let(:app) { @app }
  let(:users_path) { '/users' }
end

shared_context 'Rails app service running' do
  def start_server(rails_app_environment: { })
    service_port = RandomPort::Pool::SINGLETON.acquire
    @app.prepare_db
    server = @app.spawn_cmd \
      "./bin/rails server -p #{service_port}", { 'RAILS_ENV' => 'development', 'ORM_MODULE' => 'sequel', 'DISABLE_SPRING' => 'true' }.merge(rails_app_environment)

    uri = URI("http://localhost:#{service_port}/health")

    100.times do
      begin
        Net::HTTP.get(uri)
        break
      rescue Errno::ECONNREFUSED
        sleep 0.1
      end
    end

    [ service_port, server ]
  end

  def json_body(res)
    JSON.parse(res.body).deep_symbolize_keys
  end

  def stop_server(server)
    if server
      Process.kill 'INT', server
      Process.wait server
    end
  end
end

shared_context 'rails integration test setup' do
  let(:tmpdir) { app.tmpdir }
  before(:all) { @app.run_specs } unless use_existing_data?

  let(:appmap_json_path) { File.join(tmpdir, 'appmap/rspec', appmap_json_file) }
  let(:appmap) { JSON.parse File.read(appmap_json_path) }
  let(:events) { appmap['events'] }
end

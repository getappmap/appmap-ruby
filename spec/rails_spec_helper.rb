# frozen_string_literal: true

require 'spec_helper'
require 'active_support'
require 'active_support/core_ext'
require 'open3'

# docker compose v2 replaced the --filter flag with --status
PS_CMD=`docker-compose --version` =~ /version v2/ ?
         "docker-compose ps -q --status running" :
         "docker-compose ps -q --filter health=healthy"

def wait_for_container(app_name)
  start_time = Time.now
  until `#{PS_CMD} #{app_name}`.strip != ''
    elapsed = Time.now - start_time
    raise "Timeout waiting for container #{app_name} to be ready" if elapsed > 10

    $stderr.write '.' if elapsed > 3
    sleep 0.25
  end
end

def run_cmd(*cmd, &failed)
  out, status = Open3.capture2e(*cmd)
  return [ out, status ] if status.success?

  warn <<~WARNING
    Command failed:
    #{cmd}
    <<< Output:
    #{out}
    >>> End of output
  WARNING
  failed&.call
  raise 'Command failed'
end

shared_context 'Rails app pg database' do |fixture_dir|
  define_method(:fixture_dir) { fixture_dir }

  before(:all) do
    print_pg_logs = lambda do
      logs, = run_cmd 'docker-compose logs pg'
      puts "docker-compose logs for pg:"
      puts
      puts logs
    end

    Dir.chdir fixture_dir do
      run_cmd 'docker-compose down -v'
      cmd = 'docker-compose up -d pg'
      run_cmd cmd
      wait_for_container 'pg'

      cmd = 'docker-compose run --rm app ./create_app'
      run_cmd cmd, &print_pg_logs
    end
  end

  after(:all) do
    if ENV['NOKILL'] != 'true'
      cmd = 'docker-compose down -v'
      run_cmd cmd, chdir: fixture_dir
    end
  end
end

shared_context 'rails integration test setup' do
  def tmpdir
    'tmp/spec/AbstractControllerBase'
  end

  unless use_existing_data?
    before(:all) do
      FileUtils.rm_rf tmpdir
      FileUtils.mkdir_p tmpdir
      run_spec 'spec/controllers/users_controller_spec.rb'
      run_spec 'spec/controllers/users_controller_api_spec.rb'
    end
  end

  let(:appmap) { JSON.parse File.read File.join tmpdir, 'appmap/rspec', appmap_json_file }
  let(:appmap_json_path) { File.join(tmpdir, 'appmap/rspec', appmap_json_file) }
  let(:appmap) { JSON.parse File.read(appmap_json_path) }
  let(:events) { appmap['events'] }
end

require 'spec_helper'
require 'open3'

def wait_for_container(app_name)
  start_time = Time.now
  until (`docker-compose ps -q --filter health=healthy #{app_name}`.strip) != ''
    elapsed = Time.now - start_time
    raise "Timeout waiting for container #{app_name} to be ready" if elapsed > 10

    $stderr.write '.' if elapsed > 3
    sleep 0.25
  end
end

def run_cmd(*cmd)
  out,s = Open3.capture2e(*cmd)
  unless s.success?
    $stderr.puts <<~END
      Command failed:
      #{cmd}
      <<< Output:
      #{out}
      >>> End of output
    END
    raise 'Command failed'
  end
end

shared_context 'Rails app pg database' do
  before(:all) do
    raise "you must set @fixure_dir" unless @fixture_dir
    
    Dir.chdir @fixture_dir do 
      cmd = 'docker-compose up -d pg'
      run_cmd cmd
      wait_for_container 'pg'

      cmd = 'docker-compose run --rm app ./create_app'
      run_cmd cmd
    end
  end

  after(:all) do
    if ENV['NOKILL'] != 'true'
      cmd = 'docker-compose down -v'
      run_cmd cmd, chdir: @fixture_dir
    end
  end
end

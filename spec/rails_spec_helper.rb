require 'spec_helper'

def wait_for_container(app_name)
  start_time = Time.now
  until (`docker ps -q -f name=#{app_name} -f health=healthy`.strip) != ''
    elapsed = Time.now - start_time
    raise "Timeout waiting for container #{app_name} to be ready" if elapsed > 10

    $stderr.write '.' if elapsed > 3
    sleep 0.25
  end
end

shared_examples_for 'Rails app pg database' do
  before(:all) do
    cmd = 'docker-compose up -d pg'
    system cmd, chdir: 'spec/fixtures/rails_users_app' or raise "Command failed: #{cmd}"
    wait_for_container 'rails_users_app_pg'

    cmd = 'docker-compose run --rm app ./create_app'
    system cmd, chdir: 'spec/fixtures/rails_users_app' or raise "Command failed: #{cmd}"
  end

  after(:all) do
    if ENV['NOKILL'] != 'true'
      cmd = 'docker-compose down -v'
      system cmd, chdir: 'spec/fixtures/rails_users_app' or raise "Command failed: #{cmd}"
    end
  end
end

# frozen_string_literal: true

namespace :appmap do
  def swagger_tasks
    require 'appmap/swagger'

    AppMap::Swagger::RakeTasks.define_tasks
  end

  test_runner = lambda do |test_files|
    require "shellwords"
    file_list = test_files.map(&:shellescape).join(" ")
    env = env.merge("RAILS_ENV" => "test", "APPMAP" => "true")
    system(env, "bundle exec rspec --format documentation #{file_list}")
  end

  def depends_tasks
    require 'appmap/depends'

    test_runner = ->(test_files) { run_minitest(test_files) }

    AppMap::Depends::RakeTasks.define_tasks test_runner: test_runner
  end

  if %w[test development].member?(Rails.env)
    swagger_tasks
    depends_tasks
  end
end

if %w[test development].member?(Rails.env)
  desc 'Bring AppMaps up to date with local file modifications, and updated derived data such as Swagger files'
  task :appmap => [ :'appmap:depends:update' ]
end

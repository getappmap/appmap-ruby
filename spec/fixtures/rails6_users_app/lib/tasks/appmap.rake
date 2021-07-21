# frozen_string_literal: true

namespace :appmap do
  def swagger_tasks
    require 'appmap/swagger'
    AppMap::Swagger::RakeTasks.define_tasks
  end

  def depends_tasks
    require 'appmap/depends'
    AppMap::Depends::RakeTasks.define_tasks
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

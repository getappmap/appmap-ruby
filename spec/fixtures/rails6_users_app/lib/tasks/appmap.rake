# frozen_string_literal: true

namespace :appmap do
  def swagger_tasks
    require 'appmap/swagger'

    AppMap::Swagger::RakeTasks.define_tasks
  end

  if %w[test development].member?(Rails.env)
    swagger_tasks
  end
end

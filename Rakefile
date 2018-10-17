require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rdoc/task'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","exe/**/*")
  rd.title = 'AppMap'
end

namespace :appmap do
  desc 'Inspect the application source code for appmap annotations, and print them as JSON'
  task :inspect do
    require 'appmap'
    require 'appmap/inspector'
    require 'appmap/config'

    config = AppMap::Config.load_from_file('.appmap.yml')
    annotations = config.map(&AppMap::Inspector.method(:inspect))

    puts JSON.pretty_generate(annotations)
  end

  desc 'Run an embedded webserver which serves the appmap annotations'
  task :serve do
    require 'appmap/server/ws'
    AppMapServer.run!
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

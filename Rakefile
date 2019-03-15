require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rdoc/task'

Rake::RDocTask.new do |rd|
  rd.main = "README.rdoc"
  rd.rdoc_files.include("README.rdoc","lib/**/*.rb","exe/**/*")
  rd.title = 'AppMap'
end

namespace :appmap do
  desc 'Inspect the application source code for appmap features, and print them as JSON'
  task :inspect do
    require 'appmap'
    require 'appmap/inspect'
    require 'appmap/config'

    config = AppMap::Config.load_from_file('.appmap.yml')
    features = config.map(&AppMap::Inspect.method(:detect_features))

    puts JSON.pretty_generate(features)
  end
end

Rake::TestTask.new(:test) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task default: :test

require 'bundler/gem_tasks'
require 'rake/testtask'
require 'rdoc/task'

begin
  require 'rspec/core/rake_task'
  RSpec::Core::RakeTask.new(:spec)
rescue LoadError
  warn "Rake task 'spec' could not be loaded"
end

Rake::RDocTask.new do |rd|
  rd.main = 'README.rdoc'
  rd.rdoc_files.include(%w[README.rdoc lib/**/*.rb exe/**/*])
  rd.title = 'AppMap'
end

Rake::TestTask.new(:minitest) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/**/*_test.rb']
end

task build_docker: :build do
  require 'appmap/version'
  version = AppMap::VERSION
  system "docker build --build-arg GEM_VERSION=#{version} -t appmap-ruby_with_appmap:2.5 -f Dockerfile.ruby_with_appmap ." \
    or raise 'Docker build failed'

  Dir.chdir 'spec/fixtures/users_app' do
    system 'docker build -t appmap-users_app .' \
      or raise 'Docker build failed'
  end
end

task test: %i[build build_docker minitest spec]

task default: :test

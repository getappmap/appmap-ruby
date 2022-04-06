$: << File.join(__dir__, 'lib')

require 'rspec/core/rake_task'
require 'rake/testtask'
require 'rdoc/task'
require 'rake/extensiontask'

desc 'build the native extension'
Rake::ExtensionTask.new("appmap") do |ext|
  ext.lib_dir = "lib/appmap"
end

desc 'Install non-Ruby dependencies'
task :install do
  system 'yarn install' or raise 'yarn install failed'
end

RSpec::Core::RakeTask.new spec: %i[compile install] do |task, args|
  task.exclude_pattern = 'spec/fixtures/**/*_spec.rb'
  task.rspec_opts = '-f doc'
  if args.count > 0
    # There doesn't appear to be a value for +pattern+ that will
    # cause it to be ignored. Setting it to '' or +nil+ causes an
    # empty argument to get passed to rspec, which confuses it.
    task.pattern = 'never match this'
    task.rspec_opts += [nil, *args].join(' ')
  end
end

Rake::RDocTask.new do |rd|
  rd.main = 'README.rdoc'
  rd.rdoc_files.include(%w[README.rdoc lib/**/*.rb exe/**/*])
  rd.title = 'AppMap'
end

Rake::TestTask.new(minitest: :compile) do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/*_test.rb']
end

task test: %i[spec minitest]

task default: :test

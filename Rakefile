require 'appmap/version'
GEM_VERSION = AppMap::VERSION

require 'rake/testtask'
require 'rdoc/task'

namespace 'gem' do
  require 'bundler/gem_tasks'
end

RUBY_VERSIONS=%w[2.5 2.6]
FIXTURE_APPS=%w[rack_users_app rails_users_app rails4_users_app]

def build_base_image(ruby_version)
  system "docker build" \
         " --build-arg RUBY_VERSION=#{ruby_version} --build-arg GEM_VERSION=#{GEM_VERSION}" \
         " -t appmap:#{GEM_VERSION} -f Dockerfile.appmap ." \
  or raise 'Docker build failed'
end
  
def build_app_image(app, ruby_version)
  Dir.chdir "spec/fixtures/#{app}" do
    system "env RUBY_VERSION=#{ruby_version} GEM_VERSION=#{GEM_VERSION}" \
           " docker-compose build" \
           " --build-arg RUBY_VERSION=#{ruby_version}" \
           " --build-arg GEM_VERSION=#{GEM_VERSION}" \
    or raise 'docker-compose build failed'
  end
end

namespace :build do
  namespace :base do
    RUBY_VERSIONS.each do |ruby_version|
      desc ruby_version
      task ruby_version => ["gem:build"] do
        build_base_image(ruby_version)
      end.tap do |t|
        desc "Build all images"
        task all: t
      end
    end
  end
  
  namespace :fixtures do
    RUBY_VERSIONS.each do |ruby_version|
      namespace ruby_version do
        desc "build:fixtures:#{ruby_version}"
        FIXTURE_APPS.each do |app|
          desc app
          task app => ["base:#{ruby_version}"] do
            build_app_image(app, ruby_version)
          end.tap do |t|
            desc "Build all fixture images for #{ruby_version}"
            task all: t
          end
        end
      end
      
      desc "Build all fixture images"
      task all: ["#{ruby_version}:all"]
    end
  end

  task all: ["fixtures:all"]
end

def run_specs(ruby_version, task_args)
  require 'rspec/core/rake_task'
  require 'climate_control'
  # Define an rspec rake task for the specified Ruby version. It's hidden (i.e. doesn't have a
  # description), because it's not intended to be invoked directly
  RSpec::Core::RakeTask.new("rspec_#{ruby_version}", [:specs]) do |task, args|
    task.exclude_pattern = 'spec/fixtures/**/*_spec.rb'
    if args.count > 0
      # There doesn't appear to be a value for +pattern+ that will
      # cause it to be ignored. Setting it to '' or +nil+ causes an
      # empty argument to get passed to rspec, which confuses it.
      task.pattern = 'never match this'
      task.rspec_opts = '-f doc '
      task.rspec_opts += args.to_a.join(' ')
    end
  end
  
  # Set up the environment, then execute the rspec task we
  # created above.
  ClimateControl.modify(RUBY_VERSION: ruby_version) do
    Rake::Task["rspec_#{ruby_version}"].execute(task_args)
  end
end

namespace :spec do
  RUBY_VERSIONS.each do |ruby_version|
    desc ruby_version
    task ruby_version, [:specs] => ["build:fixtures:#{ruby_version}:all"] do |_, task_args|
      run_specs(ruby_version, task_args)
    end.tap do|t|
      desc "Run all specs"
      task :all, [:specs] => t
    end
  end
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

task test: %i[spec:all minitest]

task default: :test

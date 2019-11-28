require 'appmap/version'
GEM_VERSION = AppMap::VERSION

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
        #multitask all: t
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
      # multitask all: ["#{ruby_version}:all"]
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
      # multitask all: t
      task :all, [:specs] => t
    end
  end
end

=begin
namespace :build do
  desc 'Build everything'
  task :all

  RUBY_VERSIONS.each do |ruby_version|
    namespace ruby_version do
      desc 'Build base images for testing'
      task :all
        
      desc "Build base image for ruby #{ruby_version}"
        t = task ruby_version.to_sym =>["gem:build"] do
          require 'appmap/version'
          version = AppMap::VERSION
          system "printf ${PWD}:; echo docker build"\
                 " --build-arg RUBY_VERSION=#{ruby_version} --build-arg GEM_VERSION=#{version}"\
                 " -t appmap-ruby_with_appmap:#{ruby_version} -f Dockerfile.ruby_with_appmap ." \
          or raise 'Docker build failed'
        end
        Rake::Task[:all].enhance([t])
      end
      
      namespace :docker  do
        desc 'Build the Docker images used by the test fixtures'
        task :all
        
        FIXTURE_APPS.each do |dir|
          namespace(dir) do
            desc "Build all images for #{dir}"
            task :all
            
            desc "build fixture #{dir} for ruby #{ruby_version}"
            t = task ruby_version.to_sym => ["base:#{ruby_version}"] do
              Dir.chdir "spec/fixtures/#{dir}" do
                system "printf ${PWD}:; env RUBY_VERSION=#{ruby_version} echo docker-compose build --build-arg RUBY_VERSION=#{ruby_version}"\
                or raise 'docker-compose build failed'
              end
            end
            Rake::Task[:all].enhance([t])
          end
        end
#        Rake::Task[:all].enhance(["#{dir}:all"])
      end

      Rake::Task[:all].enhance(["docker:all"])
    end
  end
end


begin
  require 'rspec/core/rake_task'
  require 'climate_control'
  namespace(:spec) do
    desc 'Run specs for all ruby versions'
    task :all => "build:all"
    
    RUBY_VERSIONS.each do |ruby_version|

      desc "Run the specs using ruby #{ruby_version}"
      t = task(ruby_version, [:specs]) do |_, args|
        # Ask rspec to define a rake task. It's hidden (i.e. doesn't
        # have a description), because it's not intended to be invoked
        # directly
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
          Rake::Task["rspec_#{ruby_version}"].execute(args)
        end
      end

      Rake::Task[:all].enhance([t])
    end
    
  end
rescue LoadError
  warn "Rake task 'spec' could not be loaded"
end

=end

require 'rake/testtask'
require 'rdoc/task'

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

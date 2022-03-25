$: << File.join(__dir__, 'lib')
require 'appmap/version'
GEM_VERSION = AppMap::VERSION

# Make sure the local version is not behind the one on
# rubygems.org (it's ok if they're the same).
#
# If it is behind, the fixture images won't get updated with the gem
# built from the local source, so you'll wind up testing the rubygems
# version instead.
unless ENV['SKIP_VERSION_CHECK']
  require 'json'
  require 'net/http'
  rubygems_version = JSON.parse(Net::HTTP.get(URI.parse('https://rubygems.org/api/v1/gems/appmap.json')))['version']
  if Gem::Version.new(GEM_VERSION) < Gem::Version.new(rubygems_version)
    raise "#{GEM_VERSION} < #{rubygems_version}. Rebase to avoid build issues."
  end
end

require 'rake/testtask'
require 'rdoc/task'

require 'open3'
require 'rake/extensiontask'

desc 'build the native extension'
Rake::ExtensionTask.new("appmap") do |ext|
  ext.lib_dir = "lib/appmap"
end

RUBY_VERSIONS=%w[2.6 2.7 3.0 3.1].select do |version|
  travis_ruby_version = ENV['TRAVIS_RUBY_VERSION']
  next true unless travis_ruby_version

  if travis_ruby_version.index(version) == 0
    warn "Testing Ruby version #{version}, since it matches TRAVIS_RUBY_VERSION=#{travis_ruby_version}"
    next true
  end

  false
end
FIXTURE_APPS=[:rack_users_app, :rails6_users_app, :rails5_users_app, :rails7_users_app => {:ruby_version => '>= 2.7'}]

def run_cmd(*cmd)
  $stderr.puts "Running: #{cmd}"
  out, s = Open3.capture2e(*cmd)
  unless s.success?
    $stderr.puts <<-END
      Command failed:
      <<< Output:
      #{out}
      >>> End of output
    END
    raise 'Docker build failed'
  end
end

def build_base_image(ruby_version)
  run_cmd "docker build" \
         " --build-arg RUBY_VERSION=#{ruby_version}"    \
         " --build-arg GEM_VERSION=#{GEM_VERSION}"      \
         " -t appmap:#{GEM_VERSION} -f Dockerfile.appmap ."
end

def build_app_image(app, ruby_version)
  Dir.chdir "spec/fixtures/#{app}" do
    env = {"RUBY_VERSION" => ruby_version, "GEM_VERSION" => GEM_VERSION}
    run_cmd(env,
      "docker-compose build" \
      " --build-arg RUBY_VERSION=#{ruby_version}" \
      " --build-arg GEM_VERSION=#{GEM_VERSION}"  ) 
  end
end

desc 'Install non-Ruby dependencies'
task :install do
  system 'yarn install' or raise 'yarn install failed'
end

namespace :build do
  namespace :base do
    RUBY_VERSIONS.each do |ruby_version|
      desc ruby_version
      task ruby_version do
        run_system = ->(cmd) { system(cmd) or raise "Command failed: #{cmd}" }

        run_system.call 'mkdir -p pkg'
        run_system.call "gem build appmap.gemspec --output pkg/appmap-#{GEM_VERSION}.gem"
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
        FIXTURE_APPS.each do |app_spec|
          app = if app_spec.instance_of?(Hash)
            app_spec = app_spec.flatten
            version_rqt = Gem::Requirement.create(app_spec[1][:ruby_version])
            next unless version_rqt =~ (Gem::Version.new(ruby_version))
            app = app_spec[0]
          else
            app = app_spec
          end.to_s


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
    task.rspec_opts = '-f doc'
    if args.count > 0
      # There doesn't appear to be a value for +pattern+ that will
      # cause it to be ignored. Setting it to '' or +nil+ causes an
      # empty argument to get passed to rspec, which confuses it.
      task.pattern = 'never match this'
      task.rspec_opts += " " + args.to_a.join(' ')
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
    task ruby_version, [:specs] => ["install", "compile", "build:fixtures:#{ruby_version}:all"] do |_, task_args|
      run_specs(ruby_version, task_args)
    end.tap do |t|
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

Rake::TestTask.new(minitest: 'compile') do |t|
  t.libs << 'test'
  t.libs << 'lib'
  t.test_files = FileList['test/*_test.rb']
end

task spec: %i[spec:all]

task test: %i[spec:all minitest]

task default: :test

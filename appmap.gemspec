# frozen_string_literal: true

lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'appmap/version'



Gem::Specification.new do |spec|
  # ability to parameterize gem name is added intentionally, 
  # to support the possibility of unofficial releases, e.g. during CI tests
  spec.name          = (ENV['GEM_ALTERNATIVE_NAME'].to_s.empty? ? 'appmap' : ENV["GEM_ALTERNATIVE_NAME"] )
  spec.version       = AppMap::VERSION
  spec.authors       = ['Kevin Gilpin']
  spec.email         = ['kgilpin@gmail.com']

  spec.summary       = %q{Record the operation of a Ruby program, using the AppLand 'AppMap' format.}
  spec.homepage      = AppMap::URL
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = `git ls-files --no-deleted`.split("
")
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }

  spec.extensions << "ext/appmap/extconf.rb"

  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'faraday'
  spec.add_dependency 'gli'
  spec.add_dependency 'method_source'
  spec.add_dependency 'parser'
  spec.add_dependency 'rack'

  spec.add_development_dependency 'bundler', '>= 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '>= 12.3.3'
  spec.add_development_dependency 'rdoc'
  spec.add_development_dependency 'rubocop'
  spec.add_development_dependency "rake-compiler"

  # Testing
  spec.add_development_dependency 'climate_control'
  spec.add_development_dependency 'diffy'
  spec.add_development_dependency 'launchy'
  spec.add_development_dependency 'rspec'
  spec.add_development_dependency 'selenium-webdriver'
  spec.add_development_dependency 'webdrivers', '~> 4.0'
  spec.add_development_dependency 'timecop'
  spec.add_development_dependency 'hashie'
end

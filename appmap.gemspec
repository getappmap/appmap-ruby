
lib = File.expand_path('lib', __dir__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'appmap/version'

Gem::Specification.new do |spec|
  spec.name          = 'appmap'
  spec.version       = AppMap::VERSION
  spec.authors       = ['Kevin Gilpin']
  spec.email         = ['kgilpin@gmail.com']

  spec.summary       = %q{Generate animated diagrams of your Ruby application code.}
  spec.homepage      = 'https://github.com/kgilpin/appmap-ruby'
  spec.license       = 'MIT'

  # Specify which files should be added to the gem when it is released.
  # The `git ls-files -z` loads the files in the RubyGem that have been added into git.
  spec.files         = `git ls-files`.split("
")
  spec.bindir        = 'exe'
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ['lib']

  spec.add_dependency 'activesupport'
  spec.add_dependency 'parser'
  spec.add_dependency 'sinatra'

  spec.add_development_dependency 'bundler', '~> 1.16'
  spec.add_development_dependency 'minitest', '~> 5.0'
  spec.add_development_dependency 'pry-byebug'
  spec.add_development_dependency 'rake', '~> 10.0'
end

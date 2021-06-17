require 'appmap/depends/configuration'

def rake_defined?
  require 'rake'
  true
rescue LoadError
  false
end

if rake_defined?
  require 'appmap/depends/rake_tasks'
end

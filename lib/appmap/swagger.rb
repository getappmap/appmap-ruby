require 'appmap/swagger/configuration'

def rake_defined?
  require 'rake'
  true
rescue LoadError
  false
end

if rake_defined?
  require 'appmap/swagger/rake_tasks'
end

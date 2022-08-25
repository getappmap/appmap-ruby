
begin
  require 'bones'
rescue LoadError
  abort '### Please install the "bones" gem ###'
end

task :default => 'test:run'
task 'gem:release' => 'test:run'

Bones {
  name     'tabulate'
  authors  'Roy Zuo (aka roylez)'
  email    'roylzuo AT gmail DOT com'
  url      'http://tabulate.rubygems.org'
}


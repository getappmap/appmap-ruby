# -*- encoding: utf-8 -*-
# stub: tabulate 0.1.2 ruby lib

Gem::Specification.new do |s|
  s.name = "tabulate".freeze
  s.version = "0.1.2"

  s.required_rubygems_version = Gem::Requirement.new(">= 0".freeze) if s.respond_to? :required_rubygems_version=
  s.require_paths = ["lib".freeze]
  s.authors = ["Roy Zuo (aka roylez)".freeze]
  s.date = "2011-05-19"
  s.description = "Create fancy command line tables with ease.".freeze
  s.email = "roylzuo AT gmail DOT com".freeze
  s.executables = ["tabulate".freeze]
  s.extra_rdoc_files = ["History.txt".freeze, "bin/tabulate".freeze]
  s.files = ["History.txt".freeze, "bin/tabulate".freeze]
  s.homepage = "http://tabulate.rubygems.org".freeze
  s.rdoc_options = ["--main".freeze, "README.md".freeze]
  s.rubygems_version = "3.2.15".freeze
  s.summary = "Create fancy command line tables with ease.".freeze

  s.installed_by_version = "3.2.15" if s.respond_to? :installed_by_version

  if s.respond_to? :specification_version then
    s.specification_version = 3
  end

  if s.respond_to? :add_runtime_dependency then
    s.add_development_dependency(%q<bones>.freeze, [">= 3.6.5"])
  else
    s.add_dependency(%q<bones>.freeze, [">= 3.6.5"])
  end
end

# frozen_string_literal: true

# This is the file that's loaded when you require 'appmap'.
# If you require this file, we assume that you want to automatically activate all
# the AppMap functionality that seems suitable for your project.
# For example, if your project is a Rails project, the Railtie will be loaded.
# If your bundle includes rspec, the appmap/rspec will be loaded.
#
# If you don't want this "all-in" behavior, then you can use the 'require' option
# in your Gemfile to selectively activate just the AppMap features that you want. Then
# you can manually configure/require other features, elsewhere in your code.
# Note that you should always require 'appmap/agent' as early as possible, so that it can
# observe and hook as much code loading as possible.
#
# Modules that you can load independently include:
# - appmap/agent
# - appmap/railtie
# - appmap/rspec
# - appmap/minitest
# - appmap/swagger (Rake task)
# - appmap/depends (Rake task)

require 'appmap/version'
require 'appmap/agent'

lambda do
  Initializer = Struct.new(:class_name, :module_name, :gem_module_name)

  INITIALIZERS = {
    'Rails::Railtie' => Initializer.new('AppMap::Railtie', 'appmap/railtie', 'railtie'),
    'RSpec' => Initializer.new('AppMap::RSpec', 'appmap/rspec', 'rspec-core'),
    'Minitest::Unit::TestCase' => Initializer.new('AppMap::Minitest', 'appmap/minitest', 'minitest'),
    'Rake' => [
      Initializer.new('AppMap::Swagger', 'appmap/swagger', 'rake'),
      Initializer.new('AppMap::Depends', 'appmap/depends', 'rake')
    ]
  }

  TracePoint.new(:class) do |tp|
    cls_name = tp.self.name
    initializers = INITIALIZERS.delete(cls_name)
    if initializers
      initializers = [ initializers ] unless initializers.is_a?(Array)
      next if Object.const_defined?(initializers.first.class_name)

      gem_module_name = initializers.first.gem_module_name

      AppMap.config_message AppMap::Util.color(<<~LOAD_MSG, :magenta)
      When 'appmap' was loaded, '#{gem_module_name}' had not been loaded yet. Now '#{gem_module_name}' has
      just been loaded, so the following AppMap modules will be automatically required:

      #{initializers.map(&:module_name).join("\n")}

      To suppress this message, require '#{gem_module_name}' before you require 'appmap' in your Gemfile.
      LOAD_MSG
      initializers.each do |init|
        require init.module_name
      end
    end
  end.enable

  if defined?(::Rails::Railtie)
    require 'appmap/railtie'
  end
  
  if defined?(::RSpec)
    require 'appmap/rspec'
  end
  
  if defined?(::Minitest)
    require 'appmap/minitest'
  end
  
  if defined?(::Rake)
    require 'appmap/swagger'
    require 'appmap/depends'
  end
  
end.call

AppMap.initialize_configuration if ENV['APPMAP'] == 'true'

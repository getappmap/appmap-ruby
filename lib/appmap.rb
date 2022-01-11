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

begin
  require 'active_support'
  require 'active_support/core_ext'
rescue NameError
  warn 'active_support is not available. AppMap execution will continue optimistically without it...'
end

require 'appmap/version'
require 'appmap/agent'

lambda do
  Initializer = Struct.new(:class_name, :module_name, :gem_module_name)

  INITIALIZERS = {
    # In a Rails app, Rails is always defined by the time the other gems are loaded. Therefore, we
    # don't try and trap the loading of Rails itself here.
    # Emperically, Rake and RSpec are also defined before appmap is loaded whenever a Rake task or
    # RSpec tests are being run. Therefore, the only hook we need here is Minitest.
    'Minitest::Unit::TestCase' => Initializer.new('AppMap::Minitest', 'appmap/minitest', 'minitest'),
  }

  TracePoint.new(:class) do |tp|
    cls_name = tp.self.name
    initializers = INITIALIZERS.delete(cls_name)
    if initializers
      initializers = [ initializers ] unless initializers.is_a?(Array)
      next if Object.const_defined?(initializers.first.class_name)

      gem_module_name = initializers.first.gem_module_name

      AppMap::Util.startup_message AppMap::Util.color(<<~LOAD_MSG, :magenta)
      When 'appmap' was loaded, '#{gem_module_name}' had not been loaded yet. Now '#{gem_module_name}' has
      just been loaded, so the following AppMap modules will be automatically required:

      #{initializers.map(&:module_name).join("\n")}

      To suppress this message, ensure '#{gem_module_name}' appears before 'appmap' in your Gemfile.
      LOAD_MSG
      initializers.each do |init|
        require init.module_name
      end
    end
  end.enable

  if defined?(::Rails)
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

end.call unless ENV['APPMAP_AUTOREQUIRE'] == 'false'

AppMap.initialize_configuration if ENV['APPMAP'] == 'true' && ENV['APPMAP_INITIALIZE'] != 'false'

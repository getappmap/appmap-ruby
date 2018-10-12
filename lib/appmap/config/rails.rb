module AppMap
  module Config
    # Provides module configuration for the standard Rails directory layout:
    #
    # * app/models
    # * app/controllers
    # * app/views
    # * lib/tasks
    class Rails < Path
      def children
        [
          ModuleDir.new(File.join(path, 'app/models'), 'models'),
          ModuleDir.new(File.join(path, 'app/controllers'), 'controllers'),
          ModuleDir.new(File.join(path, 'lib'), 'lib')
        ]
      end
    end
  end
end

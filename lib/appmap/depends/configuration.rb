require 'appmap'

module AppMap
  module Depends
    class Configuration
      # Default file to write Rake task results.
      DEFAULT_OUTPUT_FILE = File.join('tmp', 'appmap_depends.txt')
      # Default base branches which will be checked for existance.
      DEFAULT_BASE_BRANCHES = %w[remotes/origin/main remotes/origin/master].freeze
      # Default pattern to enumerate test cases.
      DEFAULT_TEST_FILE_PATTERNS = [ 'spec/**/*_spec.rb', 'test/**/*_test.rb' ].freeze
      DEFAULT_DEPENDENT_TASKS = [ :swagger ].freeze
      DEFAULT_DESCRIPTION = 'Bring AppMaps up to date with local file modifications, and updated derived data such as Swagger files'

      attr_accessor :base_dir,
        :base_branches,
        :test_file_patterns,
        :dependent_tasks,
        :description

      class << self
        def load(config_data)
          Configuration.new.tap do |config|
            config_data.each do |k,v|
              config.send "#{k}=", v
            end
          end
        end
      end

      def initialize
        @base_dir = nil
        @base_branches = DEFAULT_BASE_BRANCHES
        @test_file_patterns = DEFAULT_TEST_FILE_PATTERNS
        @dependent_tasks = DEFAULT_DEPENDENT_TASKS
        @description = DEFAULT_DESCRIPTION
      end
    end
  end
end

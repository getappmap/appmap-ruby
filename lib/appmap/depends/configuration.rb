# frozen_string_literal: true

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
      DEFAULT_ENVIRONMENT_METHOD = 'AppMap::Depends.test_env'
      DEFAULT_RSPEC_SELECT_TESTS_METHOD = 'AppMap::Depends.select_rspec_tests'
      DEFAULT_MINITEST_SELECT_TESTS_METHOD = 'AppMap::Depends.select_minitest_tests'
      DEFAULT_RSPEC_TEST_COMMAND_METHOD = 'AppMap::Depends.rspec_test_command'
      DEFAULT_MINITEST_TEST_COMMAND_METHOD = 'AppMap::Depends.minitest_test_command'

      attr_accessor :base_dir,
        :base_branches,
        :test_file_patterns,
        :dependent_tasks,
        :description,
        :rspec_environment_method,
        :minitest_environment_method,
        :rspec_select_tests_method,
        :minitest_select_tests_method,
        :rspec_test_command_method,
        :minitest_test_command_method,

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
        @rspec_environment_method = DEFAULT_ENVIRONMENT_METHOD
        @minitest_environment_method = DEFAULT_ENVIRONMENT_METHOD
        @rspec_select_tests_method = DEFAULT_RSPEC_SELECT_TESTS_METHOD
        @minitest_select_tests_method = DEFAULT_MINITEST_SELECT_TESTS_METHOD
        @rspec_test_command_method = DEFAULT_RSPEC_TEST_COMMAND_METHOD
        @minitest_test_command_method = DEFAULT_MINITEST_TEST_COMMAND_METHOD
      end
    end
  end
end

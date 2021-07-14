# frozen_string_literal: true

require "shellwords"

module AppMap
  module Depends
    class << self
      def select_rspec_tests(test_files)
        select_tests_by_directory(test_files, 'spec')
      end

      def select_minitest_tests(test_files)
        select_tests_by_directory(test_files, 'test')
      end

      def rspec_test_command(test_files)
        "bundle exec rspec --format documentation -t '~empty' -t '~large' -t '~unstable' #{test_files}"
      end

      def minitest_test_command(test_files)
        "bundle exec rails test #{test_files}"
      end

      def select_tests_by_directory(test_files, dir)
        test_files
          .map(&method(:simplify_path))
          .uniq
          .select { |path| path.split('/').first == dir }
      end

      def normalize_test_files(test_files)
        test_files
          .map(&method(:simplify_path))
          .uniq
          .map(&:shellescape).join(' ')
      end

      def test_env
        # DISABLE_SPRING because it's likely to not have APPMAP=true
        { 'RAILS_ENV' => 'test', 'APPMAP' => 'true', 'DISABLE_SPRING' => '1' }
      end

      def simplify_path(file)
        file.index(Dir.pwd) == 0 ? file[Dir.pwd.length+1..-1] : file
      end
    end

    class TestRunner
      def initialize(test_files)
        @test_files = test_files
      end

      def run
        %i[rspec minitest].each do |framework|
          run_tests select_tests_fn(framework), build_environment_fn(framework), test_command_fn(framework)
        end
      end

      def build_environment_fn(framework)
        lookup_method("#{framework}_environment_method") do |method|
          lambda do
            method.call
          end
        end
      end

      def select_tests_fn(framework)
        lookup_method("#{framework}_select_tests_method") do |method|
          lambda do |test_files|
            method.call(test_files)
          end
        end
      end

      def test_command_fn(framework)
        lookup_method("#{framework}_test_command_method") do |method|
          lambda do |test_files|
            method.call(test_files)
          end
        end
      end

      protected

      def lookup_method(setting_name, &block)
        method_name = AppMap.configuration.depends_config.send(setting_name)
        method_tokens = method_name.split(/\:\:|\./)
        cls = Object
        while method_tokens.size > 1
          cls = cls.const_get(method_tokens.shift)
        end
        cls.public_method(method_tokens.first)
      end

      def run_tests(select_tests_fn, env_fn, test_command_fn)
        test_files = select_tests_fn.(@test_files)
        return if test_files.empty?

        test_files = Depends.normalize_test_files(test_files)
        command = test_command_fn.(test_files)
        succeeded = system(env_fn.(), command)
        raise %Q|Command failed: #{command}| unless succeeded
      end
    end
  end
end

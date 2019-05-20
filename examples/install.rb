#!/usr/bin/env ruby

$LOAD_PATH.unshift File.join(__dir__)

class Install
  attr_reader :example_dir

  def initialize
    @pwd = __dir__
    @example_dir = File.expand_path('../tmp/install', __dir__)
  end

  def run
    create_project_dir
    in_project_dir do
      create_example_project
      in_example_dir do
        bundle
        Bundler.with_clean_env do
          inspect_example_project
        end
        print_inventory
      end
    end
  end

  def create_example_project
    FileUtils.cp_r File.join(@pwd, 'mock_webapp'), '.'
  end

  def bundle
    system 'bundle --local > /dev/null' or raise "Failed to bundle --local'"
  end

  def create_project_dir
    FileUtils.rm_rf example_dir
    FileUtils.mkdir_p example_dir
  end

  def in_project_dir(&block)
    Dir.chdir example_dir, &block
  end

  def in_example_dir(&block)
    puts "in example dir"
    Dir.chdir 'mock_webapp', &block
  end

  def inspect_example_project
    FileUtils.mkdir_p '.appmap'
    @inventory = `bundle exec #{File.expand_path('../exe/inspect', __dir__)}` or raise "Failed to inspect the sample project"
  end

  def print_inventory
    puts @inventory
  end
end

Install.new.run

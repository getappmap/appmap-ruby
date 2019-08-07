#!/usr/bin/env ruby

$LOAD_PATH.unshift File.join(__dir__)
require 'fileutils'

module Command
  def run_command command
    `#{command}`.tap do |_|
      raise "Command failed: #{command}" unless $? == 0
    end
  end
end

class InProjectDirectory
  attr_reader :project_dir

  def initialize
    @project_dir = File.expand_path('../tmp/install', __dir__)
  end

  def perform(&block)
    FileUtils.rm_rf project_dir
    FileUtils.mkdir_p project_dir
    Dir.chdir project_dir, &block
  end
end

class InstallExampleCode
  def perform
    FileUtils.cp_r File.join(__dir__, 'mock_webapp'), '.'
  end
end

class InExampleDirectory
  def perform(&block)
    Dir.chdir 'mock_webapp', &block
  end
end

class InstallAppmapGem
  include Command

  def perform
    run_command 'bundle --local > /dev/null'
  end
end

class InspectExampleProject
  include Command

  def perform
    FileUtils.mkdir_p '.appmap'
    run_command "bundle exec #{File.expand_path('../exe/appmap', __dir__)} inspect -o appmap.json"
  end
end

class PrintInventory
  def initialize(inventory)
    @inventory = inventory
  end

  def perform
    puts @inventory
  end
end

InProjectDirectory.new.perform do
  InstallExampleCode.new.perform
  InExampleDirectory.new.perform do
    InstallAppmapGem.new.perform

    inventory = InspectExampleProject.new.perform
    PrintInventory.new(inventory).perform
  end
end


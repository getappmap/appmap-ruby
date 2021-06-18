require_relative '../spec_helper'

DEPENDS_TEST_DIR = 'spec/fixtures/depends'
DEPENDS_BASE_DIR = DEPENDS_TEST_DIR

def update_appmap_index
  require 'appmap/node_cli'
  AppMap::NodeCLI.new(verbose: ENV['DEBUG'] == 'true', appmap_dir: DEPENDS_TEST_DIR).index_appmaps
end

RSpec.configure do |rspec|
  rspec.before do
    Dir.glob("#{DEPENDS_TEST_DIR}/*.appmap.json").each { |fname| FileUtils.touch fname }
    update_appmap_index

    FileUtils.rm_rf 'spec/tmp'
    FileUtils.mkdir_p 'spec/tmp'
  end
end

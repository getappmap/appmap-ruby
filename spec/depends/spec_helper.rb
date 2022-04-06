require_relative '../spec_helper'

DEPENDS_TEST_DIR = 'spec/fixtures/depends'
DEPENDS_BASE_DIR = DEPENDS_TEST_DIR

def update_appmap_index
  cmd = [
    './exe/appmap-index',
    '--appmap-dir',
    DEPENDS_TEST_DIR
  ]
  if ENV['DEBUG'] == 'true'
    cmd << '--verbose'
  end

  system cmd.join(' ') or raise "Failed to update AppMap index in #{DEPENDS_TEST_DIR}"
end


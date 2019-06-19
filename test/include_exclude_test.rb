# frozen_string_literal: true

require 'test_helper'
require 'appmap/config'

class IncludeExcludeTest < Minitest::Test
  include FixtureFile

  INCLUDE_EXCLUDE_FIXTURE_DIR = File.join(FIXTURE_DIR, 'includes_excludes')

  def setup
    @package_dir = AppMap::Config::PackageDir.new(File.join(INCLUDE_EXCLUDE_FIXTURE_DIR, 'lib')).tap do |c|
      c.package_name = 'include_exclude'
    end
  end

  def test_exclude_dir
    @package_dir.exclude = %w[b]
    assert_equal %w[lib/root_1.rb lib/a], normalized_children
  end

  def test_exclude_file
    @package_dir.exclude = %w[root_1.rb]
    assert_equal %w[lib/a lib/b], normalized_children
  end

  def test_exclude_subfile
    @package_dir.exclude = %w[a/a_1.rb root_1.rb b]
    assert_equal %w[lib/a], normalized_children
    assert_equal %w[lib/a/a_2.rb lib/a/x], normalize_paths(@package_dir.children.first.children.map(&:path))
  end

  def test_exclude_subdir
    @package_dir.exclude = %w[a/a_1.rb root_1.rb b a/x]
    assert_equal %w[lib/a], normalized_children
    assert_equal %w[lib/a/a_2.rb], normalize_paths(@package_dir.children.first.children.map(&:path))
  end

  protected

  def normalized_children
    normalize_paths(@package_dir.children.map(&:path))
  end

  def normalize_paths(paths)
    paths.map { |p| Pathname.new(p).to_s.gsub("#{INCLUDE_EXCLUDE_FIXTURE_DIR}/", '') }
  end
end

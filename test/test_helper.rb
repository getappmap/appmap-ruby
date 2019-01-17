$LOAD_PATH.unshift File.expand_path('../lib', __dir__)
require 'appmap'

require 'minitest/autorun'

FIXTURE_DIR = File.join(__dir__, 'fixtures')
PARSE_FILE_FIXTURE_DIR = File.join(FIXTURE_DIR, 'parse_file')
INSPECT_MODULE_FIXTURE_DIR = File.join(FIXTURE_DIR, 'inspect_module')

module FixturePath
  def parse_fixture_file(path)
    File.join(FIXTURE_DIR, 'parse_file', path)
  end
end

module FixtureFile
  include FixturePath

  def assert_fixture_features(path)
    features = Array(AppMap::Inspector.new(parse_fixture_file(path)).parse)

    fixup_fixture_path = lambda do |a|
      a.location = a.location.gsub(PARSE_FILE_FIXTURE_DIR, '$FIXTURE_DIR')
      a.children.each(&fixup_fixture_path)
    end
    features.each(&fixup_fixture_path)

    expectation = `ruby #{parse_fixture_file(path)}`
    assert_equal JSON.pretty_generate(Array(JSON.parse(expectation))),
                 JSON.pretty_generate(features.map(&:to_h))
  end
end

# Verify that the fixture files are valid

Dir.new(PARSE_FILE_FIXTURE_DIR)
   .entries
   .select { |e| File.file?(File.join(PARSE_FILE_FIXTURE_DIR, e)) && e.index('.rb') == e.size - 3 }
   .each do |e|
  fname = File.join(PARSE_FILE_FIXTURE_DIR, e)
  raise "Fixture #{fname.inspect} is not valid" unless system("ruby #{fname} > /dev/null")
end

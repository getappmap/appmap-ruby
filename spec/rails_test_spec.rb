require 'rails_spec_helper'

# Rails5 doesn't work with Ruby 3.x, Rails 7 doesn't work with Ruby < 2.7.
def default_rails_versions
  if testing_ruby_2?
    if Gem::Requirement.create('>= 2.7') =~ Gem::Version.new(RUBY_VERSION)
      [ 5, 6, 7 ]
    else
      [ 5, 6 ]
    end
  else
    [ 6, 7 ]
  end
end

def rails_versions
  Array(ENV['RAILS_VERSIONS'] || default_rails_versions)
end

describe 'Rails' do
  rails_versions.each do |rails_major_version| # rubocop:disable Metrics/BlockLength
    context "#{rails_major_version}" do
      include_context 'Rails app pg database', "spec/fixtures/rails#{rails_major_version}_users_app" unless use_existing_data?

      it 'runs tests with APPMAP=true' do
        app.prepare_db
        app.run_cmd \
          'bundle exec rake',
          'RAILS_ENV' => 'test',
          'APPMAP' => 'true',
          'TEST_OPTS' => '--verbose'
      end
    end
  end
end

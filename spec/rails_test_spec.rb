require 'rails_spec_helper'

describe 'Rails' do
  rails_versions.each do |rails_version|
    include_context 'rails app', rails_version

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

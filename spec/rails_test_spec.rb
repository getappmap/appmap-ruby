require 'rails_spec_helper'

describe 'Rails' do
  rails_versions.each do |rails_version|
    include_context 'rails app', rails_version

    it 'runs tests' do
      app.prepare_db
      app.run_cmd \
        'bundle exec rake',
        'RAILS_ENV' => 'test',
        'TEST_OPTS' => '--verbose'
    end
  end
end

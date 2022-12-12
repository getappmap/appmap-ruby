require 'rails_spec_helper'

describe 'HookLog' do
  include_context 'rails app', 6

  let(:hook_log_file) { 'spec/fixtures/rails6_users_app/appmap_hook.log' }

  before do
    FileUtils.rm_f hook_log_file
  end

  context 'with APPMAP_LOG_HOOK=true' do
    it 'runs creates appmap_hook.log' do
      app.prepare_db
      app.run_cmd \
        'bundle exec rake',
        'RAILS_ENV' => 'test',
        'APPMAP_LOG_HOOK' => 'true'

      expect(Dir['spec/fixtures/rails6_users_app/*']).to include(hook_log_file)
    end
    it 'results can be directed to stderr' do
      app.prepare_db
      stdout, stderr, = app.capture_cmd \
        'bundle exec rake',
        'RAILS_ENV' => 'test',
        'APPMAP_LOG_HOOK' => 'true',
        'APPMAP_LOG_HOOK_FILE' => 'stderr'

      expect(Dir['spec/fixtures/rails6_users_app/*']).to_not include(hook_log_file)
      expect(stderr.strip).to include('Elapsed time:')
    end
  end
end

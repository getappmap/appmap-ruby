#!/usr/bin/env ruby
# frozen_string_literal: true

require 'test_helper'

class AgentSetupInitTest < Minitest::Test
  def test_status_gem
    output = `./exe/appmap-agent-status`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = {
      test_commands: [],
      properties: {
        config: {
          app: 'AppMap Rubygem',
          present: true,
          valid: true
        },
        project: {
          agentVersion: AppMap::VERSION,
          language: 'ruby',
          remoteRecordingCapable: false,
          integrationTests: false
        }
      }
    }
    assert_equal JSON.pretty_generate(expected), output.strip
  end

  def test_status_rails_app
    def test_status
      output = `cd spec/fixtures/rails6_users_app && bundle exec ../../../exe/appmap-agent-status`
      assert_equal 0, $CHILD_STATUS.exitstatus
      expected = {
        test_commands: [
          {
            framework: :rspec,
            command: 'APPMAP=true bundle exec rspec spec/controllers'
          },
          {
            framework: :minitest,
            command: 'APPMAP=true bundle exec ruby test/controllers && APPMAP=true bundle exec ruby test/integration'
          },
          {
            framework: :cucumber,
            command: 'APPMAP=true bundle exec cucumber'
          }
        ],
        properties: {
          config: {
            app: nil,
            present: true,
            valid: true
          },
          project: {
            agentVersion: AppMap::VERSION,
            language: 'ruby',
            remoteRecordingCapable: false,
            integrationTests: true
          }
        }
      }
      assert_equal JSON.pretty_generate(expected), output.strip
    end
  end
end

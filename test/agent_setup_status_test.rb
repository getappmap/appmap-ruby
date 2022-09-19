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
          valid: false
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
    output = `cd spec/fixtures/rails6_users_app && bundle exec ../../../exe/appmap-agent-status`
    assert_equal 0, $CHILD_STATUS.exitstatus
    expected = {
      test_commands: [
        {
          framework: :rspec,
          command: {
            program: 'bundle',
            args: %w[exec rspec ./spec/controllers],
            environment: { }
          }
        },
        {
          framework: :minitest,
          command: {
            program: 'bundle',
            args: %w[exec ruby ./test/controllers],
            environment: { }
          }
        },
        {
          framework: :minitest,
          command: {
            program: 'bundle',
            args: %w[exec ruby ./test/integration],
            environment: { }
          }
        }
      ],
      properties: {
        config: {
          app: 'rails6_users_app',
          present: true,
          valid: false
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

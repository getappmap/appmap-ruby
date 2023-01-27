require 'rails_helper'
require 'rack/test'
require "swagger_helper"

# rubocop:disable RSpec/EmptyExampleGroup

RSpec.describe Api::UsersController, type: :request do
  describe 'POST /api/users' do
    path "/api/users" do
      post "new user" do

        describe 'with rswag' do
          # demonstrate bug with Rswag::Specs::ExampleGroupHelpers::run_test!
          #
          # NoMethodError:
          #   undefined method `metadata' for nil:NilClass
          #
          # /home/test/.rbenv/versions/3.0.2/lib/ruby/gems/3.0.0/gems/rswag-specs-2.8.0/lib/rswag/specs/example_group_helpers.rb:135:in `block in run_test!'
          # /home/test/src/appmap-ruby/lib/appmap/rspec.rb:241:in `instance_exec'
          response "422", "Unprocessable entity" do
            run_test!
          end
        end

      end
    end
  end
end

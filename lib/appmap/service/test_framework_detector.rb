# frozen_string_literal: true

module AppMap
  module Service
    class TestFrameworkDetector
      class << self
        def rspec_present?
          Gem.loaded_specs.has_key?('rspec-core')
        end

        def minitest_present?
          Gem.loaded_specs.has_key?('minitest')
        end

        def cucumber_present?
          Gem.loaded_specs.has_key?('cucumber')
        end
      end
    end
  end
end
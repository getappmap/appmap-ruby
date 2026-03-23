# frozen_string_literal: true

module AppMap
  module Service
    class TestFrameworkDetector
      class << self
        def rspec_present?
          gem_available?('rspec-core')
        end

        def minitest_present?
          gem_available?('minitest')
        end

        def cucumber_present?
          gem_available?('cucumber')
        end

        private

        def gem_available?(name)
          Gem.loaded_specs.has_key?(name) || !Gem::Specification.find_by_name(name).nil?
        rescue Gem::MissingSpecError
          false
        end
      end
    end
  end
end
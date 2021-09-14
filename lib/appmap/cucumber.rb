# frozen_string_literal: true

require 'appmap/util'
require 'fileutils'

module AppMap
  module Cucumber
    APPMAP_OUTPUT_DIR = 'tmp/appmap/cucumber'
    
    ScenarioAttributes = Struct.new(:name, :feature, :feature_group)

    ProviderStruct = Struct.new(:scenario) do
      def feature_group
        # e.g. <Cucumber::Core::Ast::Location::Precise: cucumber/api/features/authenticate.feature:1>
        feature_path.split('/').last.split('.')[0]
      end
    end

    # ProviderBefore4 provides scenario name, feature name, and feature group name for Cucumber
    # versions before 4.0.
    class ProviderBefore4 < ProviderStruct
      def attributes
        ScenarioAttributes.new(scenario.name, scenario.feature.name, feature_group)
      end

      def feature_path
        scenario.feature.location.to_s
      end
    end

    # Provider4 provides scenario name, feature name, and feature group name for Cucumber
    # versions 4.0 and later.
    class Provider4 < ProviderStruct
      def attributes
        ScenarioAttributes.new(scenario.name, scenario.name.split(' ')[0..1].join(' '), feature_group)
      end

      def feature_path
        scenario.location.file
      end
    end

    class << self
      def init
        warn 'Configuring AppMap recorder for Cucumber'

        FileUtils.mkdir_p APPMAP_OUTPUT_DIR
      end
      
      def write_scenario(scenario, appmap)
        appmap['metadata'] = update_metadata(scenario, appmap['metadata'])
        scenario_filename = AppMap::Util.scenario_filename(appmap['metadata']['name'])

        AppMap::Util.write_appmap(File.join(APPMAP_OUTPUT_DIR, scenario_filename), JSON.generate(appmap))
      end

      def enabled?
        ENV['APPMAP'] == 'true'
      end

      def run
        init
      end
      
      protected

      def cucumber_version
        Gem.loaded_specs['cucumber']&.version&.to_s
      end

      def provider(scenario)
        major, = cucumber_version.split('.').map(&:to_i)
        if major < 4
          ProviderBefore4
        else
          Provider4
        end.new(scenario)
      end

      def update_metadata(scenario, base_metadata)
        attributes = provider(scenario).attributes

        base_metadata.tap do |m|
          m['name'] = attributes.name
          m['feature'] = attributes.feature
          m['feature_group'] = attributes.feature_group
          m['labels'] ||= []
          m['labels'] += (scenario.tags&.map(&:name) || [])
          m['frameworks'] ||= []
          m['frameworks'] << {
            'name' => 'cucumber',
            'version' => Gem.loaded_specs['cucumber']&.version&.to_s
          }
          m['recorder'] = {
            'name' => 'cucumber'
          }
        end
      end
    end
  end
end

if AppMap::Cucumber.enabled?
  require 'appmap'

  AppMap::Cucumber.run
end

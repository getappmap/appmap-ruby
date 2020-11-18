# frozen_string_literal: true

if AppMap::Cucumber.enabled?
  Around('not @appmap-disable') do |scenario, block|
    appmap = AppMap.record do
      block.call
    end

    AppMap::Cucumber.write_scenario(scenario, appmap)
  end
end

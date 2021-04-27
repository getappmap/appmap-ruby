# frozen_string_literal: true

require 'appmap'
require 'json'

tracer = AppMap.tracing.trace

at_exit do
  AppMap.tracing.delete(tracer)

  events = [].tap do |event_list|
    event_list << tracer.next_event.to_h while tracer.event?
  end

  metadata = AppMap.detect_metadata
  metadata[:recorder] = {
    name: 'record_process'
  }

  appmap = {
    'version' => AppMap::APPMAP_FORMAT_VERSION,
    'metadata' => metadata,
    'classMap' => AppMap.class_map(tracer.event_methods),
    'events' => events
  }
  AppMap::Util.write_appmap('appmap.json', JSON.generate(appmap))
end

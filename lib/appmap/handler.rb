# frozen_string_literal: true

require 'active_support/inflector/methods'

module AppMap
  # Specific hook handler classes and general related utilities.
  module Handler
    TEMPLATE_RENDER_FORMAT = 'appmap.handler.template.return_value_format'
    TEMPLATE_RENDER_VALUE = 'appmap.handler.template.return_value'

    # Try to find handler module with a given name.
    #
    # If the module is not loaded, tries to require the appropriate file
    # using the usual conventions, eg. `Acme::Handler::AppMap` will try
    # to require `acme/handler/app_map`, then `acme/handler` and
    # finally `acme`. Raises NameError if the module could not be loaded
    # this way.
    def self.find(name)
      begin
        return Object.const_get name
      rescue NameError
        try_load ActiveSupport::Inflector.underscore name
      end
      Object.const_get name
    end

    def self.try_load(fname)
      fname = fname.sub %r{^app_map/}, 'appmap/'
      fname = fname.split '/'
      until fname.empty?
        begin
          require fname.join '/'
          return
        rescue LoadError
          # pass
        end
        fname.pop
      end
    end
  end
end

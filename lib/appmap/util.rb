# frozen_string_literal: true

module AppMap
  module Util
    class << self
      # scenario_filename builds a suitable file name from a scenario name.
      # Special characters are removed, and the file name is truncated to fit within
      # shell limitations.
      def scenario_filename(name, max_length: 255, separator: '_', extension: '.appmap.json')
        # Cribbed from v5 version of ActiveSupport:Inflector#parameterize:
        # https://github.com/rails/rails/blob/v5.2.4/activesupport/lib/active_support/inflector/transliterate.rb#L92
        # Replace accented chars with their ASCII equivalents.

        fname = name.encode('utf-8', invalid: :replace, undef: :replace, replace: '_')

        # Turn unwanted chars into the separator.
        fname.gsub!(/[^a-z0-9\-_]+/i, separator)

        re_sep = Regexp.escape(separator)
        re_duplicate_separator        = /#{re_sep}{2,}/
        re_leading_trailing_separator = /^#{re_sep}|#{re_sep}$/i

        # No more than one of the separator in a row.
        fname.gsub!(re_duplicate_separator, separator)

        # Finally, Remove leading/trailing separator.
        fname.gsub!(re_leading_trailing_separator, '')

        if (fname.length + extension.length) > max_length
          require 'base64'
          require 'digest'
          fname_digest = Base64.urlsafe_encode64 Digest::MD5.digest(fname), padding: false
          fname[max_length - fname_digest.length - extension.length - 1..-1] = [ '-', fname_digest ].join
        end

        [ fname, extension ].join
      end

      # sanitize_paths removes ephemeral values from objects with
      # embedded paths (e.g. an event or a classmap), making events
      # easier to compare across runs.
      def sanitize_paths(h)
        require 'hashie'
        h.extend(Hashie::Extensions::DeepLocate)
        keys = %i(path location)
        h.deep_locate ->(k,v,o) {
          next unless keys.include?(k)
          
          fix = ->(v) {v.gsub(%r{#{Gem.dir}/gems/.*(?=lib)}, '')}
          keys.each {|k| o[k] = fix.(o[k]) if o[k] }
        }

        h
      end
      
      # sanitize_event removes ephemeral values from an event, making
      # events easier to compare across runs.
      def sanitize_event(event, &block)
        event.delete(:thread_id)
        event.delete(:elapsed)
        delete_object_id = ->(obj) { (obj || {}).delete(:object_id) }
        delete_object_id.call(event[:receiver])
        delete_object_id.call(event[:return_value])
        (event[:parameters] || []).each(&delete_object_id)
        (event[:exceptions] || []).each(&delete_object_id)

        case event[:event]
        when :call
          sanitize_paths(event)
        end

        event
      end
    end
  end
end

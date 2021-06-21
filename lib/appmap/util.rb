# frozen_string_literal: true

require 'bundler'

module AppMap
  module Util
    # https://wynnnetherland.com/journal/a-stylesheet-author-s-guide-to-terminal-colors/
    # Embed in a String to clear all previous ANSI sequences.
    CLEAR   = "\e[0m"
    BOLD    = "\e[1m"

    # Colors
    BLACK   = "\e[30m"
    RED     = "\e[31m"
    GREEN   = "\e[32m"
    YELLOW  = "\e[33m"
    BLUE    = "\e[34m"
    MAGENTA = "\e[35m"
    CYAN    = "\e[36m"
    WHITE   = "\e[37m"

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
        %i[parameters exceptions message].each do |field|
          (event[field] || []).each(&delete_object_id)
        end
        %i[http_client_request http_client_response http_server_request http_server_response].each do |field|
          headers = event.dig(field, :headers)
          next unless headers

          headers['Date'] = '<instanceof date>' if headers['Date']
          headers['Server'] = headers['Server'].match(/^(\w+)/)[0] if headers['Server']
        end

        case event[:event]
        when :call
          sanitize_paths(event)
        end

        event
      end

      def select_headers(env)
        # Rack prepends HTTP_ to all client-sent headers.
        matching_headers = env
          .select { |k,v| k.start_with? 'HTTP_'}
          .reject { |k,v| v.blank? }
          .each_with_object({}) do |kv, memo|
            key = kv[0].sub(/^HTTP_/, '').split('_').map(&:capitalize).join('-')
            value = kv[1]
            memo[key] = value
          end
        matching_headers.blank? ? nil : matching_headers
      end

      def normalize_path(path)
        if path.index(Dir.pwd) == 0 && !path.index(Bundler.bundle_path.to_s)
          path[Dir.pwd.length + 1..-1]
        else
          path
        end
      end

      # Convert a Rails-style path from /org/:org_id(.:format)
      # to Swagger-style paths like /org/{org_id}
      def swaggerize_path(path)
        path = path.split('(.')[0]
        tokens = path.split('/')
        tokens.map do |token|
          token.gsub /^:(.*)/, '{\1}'
        end.join('/')
      end

      # Atomically writes AppMap data to +filename+.
      def write_appmap(filename, appmap)
        require 'fileutils'
        require 'tmpdir'

        # This is what Ruby Tempfile does; but we don't want the file to be unlinked.
        mode = File::RDWR | File::CREAT | File::EXCL
        ::Dir::Tmpname.create([ 'appmap_', '.json' ]) do |tmpname|
          tempfile = File.open(tmpname, mode)
          tempfile.write(appmap)
          tempfile.close
          # Atomically move the tempfile into place.
          FileUtils.mv tempfile.path, filename
        end
      end

      def color(text, color, bold: false)
        color = Util.const_get(color.to_s.upcase) if color.is_a?(Symbol)
        bold  = bold ? BOLD : ""
        "#{bold}#{color}#{text}#{CLEAR}"
      end

      def classify(word)
        word.split(/[\-_]/).map(&:capitalize).join
      end

      def deep_dup(hash)
        # This is a simple way to avoid the need for deep_dup from activesupport.
        Marshal.load(Marshal.dump(hash))
      end
    end
  end
end

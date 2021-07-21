# frozen_string_literal: true

require 'shellwords'
require 'appmap/node_cli'

module AppMap
  module Depends
    # +Command+ wraps the Node +depends+ command.
    class NodeCLI < ::AppMap::NodeCLI
      # Directory name to prefix to the list of modified files which is provided to +depends+.
      attr_accessor :base_dir
      # AppMap field to report.
      attr_accessor :field

      def initialize(verbose:, appmap_dir:)
        super(verbose: verbose, appmap_dir: appmap_dir)

        @base_dir = nil
        @field = 'source_location'
      end

      # Returns the source_location field of every AppMap that is "out of date" with respect to one of the
      # +modified_files+.
      def depends(modified_files = nil)
        index_appmaps

        cmd = %w[depends]
        cmd += [ '--field', field ] if field
        cmd += [ '--appmap-dir', appmap_dir ] if appmap_dir
        cmd += [ '--base-dir', base_dir ] if base_dir

        options = {}
        if modified_files
          cmd << '--stdin-files'
          options[:stdin_data] = modified_files.map(&:shellescape).join("\n")
          warn "Checking modified files: #{modified_files.join(' ')}" if verbose
        end

        stdout, = command cmd, options
        stdout.split("\n")
      end
    end
  end
end

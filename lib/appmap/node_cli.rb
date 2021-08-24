require 'open3'
require 'shellwords'
require 'appmap/util'
require 'appmap/command_error'

module AppMap
  # Utilities for invoking the +@appland/appmap+ CLI.
  class NodeCLI
    APPMAP_JS = Pathname.new(__dir__).join('../../node_modules/@appland/appmap/src/cli.js').expand_path.to_s

    attr_reader :verbose
    # Directory to scan for AppMaps.
    attr_accessor :appmap_dir

    def initialize(verbose: false, appmap_dir: AppMap::DEFAULT_APPMAP_DIR)
      @verbose = verbose
      @appmap_dir = appmap_dir

      detect_nodejs
    end

    def detect_nodejs
      do_fail('node', 'please install NodeJS') unless system('node --version 2>&1 > /dev/null')
      true
    end

    def index_appmaps
      command [ 'index', '--appmap-dir', appmap_dir ]
      true
    end

    def command(command, options = {})
      command.unshift << '--verbose' if verbose
      command.unshift APPMAP_JS
      command.unshift 'node'

      warn command.join(' ') if verbose
      stdout, stderr, status = Open3.capture3({ 'NODE_OPTIONS' => '--trace-warnings' }, *command.map(&:shellescape), options)
      stdout_msg = stdout.split("\n").map {|line| "stdout: #{line}"}.join("\n") unless Util.blank?(stdout)
      stderr_msg = stderr.split("\n").map {|line| "stderr: #{line}"}.join("\n") unless Util.blank?(stderr)
      if verbose
        warn stdout_msg if stdout_msg
        warn stderr_msg if stderr_msg
      end
      unless status.exitstatus == 0
        raise CommandError.new(command, [ stdout_msg, stderr_msg ].compact.join("\n"))
      end
      [ stdout, stderr ]
    end

    protected

    def do_fail(command, msg)
      command = command.join(' ') if command.is_a?(Array)
      warn [ command, msg ].join('; ') if verbose
      raise CommandError.new(command, msg)
    end
  end
end

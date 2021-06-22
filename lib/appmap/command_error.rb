module AppMap
  # Raised when a system / shell command fails.
  class CommandError < StandardError
    attr_reader :command, :msg

    def initialize(command, msg = nil)
      super [ "Command failed: #{command}", msg ].compact.join('; ')

      @command = command
      @msg = msg
    end
  end
end

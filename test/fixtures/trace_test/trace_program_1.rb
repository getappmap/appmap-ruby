module Fixtures
  module TraceTest
    module TraceProgram1
      class Main
        def initialize(printer)
          @printer = printer
        end

        def say(msg)
          @printer.say(msg)
        end
      end

      module Printer
        # Stdout is a class with a 'say' instance method.
        class Stdout
          def say(msg)
            puts(msg)
          end
        end

        # Define 'say' on a static class method.
        class Stderr
          class << self
            def say(msg)
              warn(msg)
            end
          end
        end

        # make_stderr_printer builds an object which modifies 'say' to print to stderr.
        def Printer.make_stderr_printer
          Stdout.new.tap do |err_printer|
            class << err_printer
              def say(msg)
                warn(msg)
              end
            end
          end
        end
      end
    end
  end
end

# frozen_string_literal: true

module AppMap
  OpenStruct = Struct.new(:appmap)

  class Open < OpenStruct
    attr_reader :port

    def perform
      server = run_server
      open_browser
      server.kill
    end

    def page
      require 'rack/utils'
      <<~PAGE
      <!DOCTYPE html>
      <html>
      <head>
        <title>&hellip;</title>
        <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
        <script type="text/javascript">
        function dosubmit() { document.forms[0].submit(); }
        </script>
      </head>
      <body onload="dosubmit();">
        <form action="https://app.land/scenario_uploads" method="POST" accept-charset="utf-8">
        <input type="hidden" name="data" value='#{Rack::Utils.escape_html appmap.to_json}'>
        </form>
      </body>
      </html>
      PAGE
    end

    def run_server(timeout: 10)
      require 'rack'
      thread = Thread.new do
        Rack::Handler::WEBrick.run(
          lambda do |env|
            [200, { 'Content-Type' => 'text/html' }, [page]]
          end,
          Port: 0,
          BindAddress: "127.0.0.1"
        ) do |server|
          @port = server.config[:Port]
        end
      end
      deadline = Process.clock_gettime(Process::CLOCK_MONOTONIC) + timeout
      sleep 0.1 until @port || !thread.alive? || Process.clock_gettime(Process::CLOCK_MONOTONIC) >= deadline

      unless thread.alive?
        thread.value # re-raise any exception from the server thread
        raise "Server thread exited unexpectedly"
      end

      return thread if @port

      raise "Timed out waiting for server to start after #{timeout} s"
    end

    def open_browser
      system 'open', "http://localhost:#{@port}"
      sleep 5.0
    end
  end
end

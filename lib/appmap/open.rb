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

    def run_server
      require 'rack'
      Thread.new do
        Rack::Handler::WEBrick.run(
          lambda do |env|
            return [200, { 'Content-Type' => 'text/html' }, [page]]
          end,
          :Port => 0
        ) do |server|
          @port = server.config[:Port]
        end
      end.tap do
        sleep 1.0
      end
    end

    def open_browser
      system 'open', "http://localhost:#{@port}"
      sleep 5.0
    end
  end
end

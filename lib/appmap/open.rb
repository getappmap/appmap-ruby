# frozen_string_literal: true

module AppMap
  OpenStruct = Struct.new(:appmap)

  class Open < OpenStruct
    def perform
      require 'rack/utils'
      page = <<~PAGE
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

      port = nil
      server_thread = Thread.new do
        require 'rack'
        Rack::Handler::WEBrick.run(
          lambda do |env|
            return [200, { 'Content-Type' => 'text/html' }, [page]]
          end,
          :Port => 0
        ) do |server|
          port = server.config[:Port]
        end
      end
      sleep 1.0

      system 'open', "http://localhost:#{port}"

      sleep 5.0

      server_thread.kill
    end
  end
end

module AppMap
  module Handler
    module Rails
      class << self
        def test_route(app, request)
          app.matches?(request)
        rescue
          test_route_warn(request)
          false
        end

        protected

        @test_route_warned = false

        def test_route_warn(request)
          return if @test_route_warned

          @test_route_warned = true
          warn "Notice: Failed to match route for #{request&.path_info || "an unknown path"}: #{$ERROR_INFO}"
          warn "Notice: A solution for this problem is forthcoming, see https://github.com/getappmap/appmap-ruby/issues/360"
        end
      end
    end
  end
end

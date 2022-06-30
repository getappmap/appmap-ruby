module AppMap
  module Inject
    class RequestInjector
      Config = Struct.new(:route, :invocation_number, :parameters) do
        def initialize(*args)
          super

          self.invocation_number ||= 0
        end
      end

      def initialize(config)
        @config = config
        @invocation_index = 0
      end

      def inject(request)
        normalized_path = AppMap::Util.route_from_request(request)
        return unless [ request.request_method.upcase, normalized_path ].join(' ') == @config.route

        invocation_number = @config.invocation_number || 0
        begin
          return unless invocation_number == @invocation_index
        ensure
          @invocation_index += 1
        end
        
        request.params.merge!(@config.parameters)
        request.env['rack.request.query_hash'].merge!(@config.parameters)
      end

      class << self
        def load
          inject_file = ENV['APPMAP_INJECT']
          return nil unless inject_file

          inject_cmd = YAML.load(File.read(ENV['APPMAP_INJECT']))
          config = Config.new.tap do |config|
            inject_cmd.each do |k,v|
              config.send "#{k}=", v
            end
          end
          RequestInjector.new config
        end
      end
    end
  end
end

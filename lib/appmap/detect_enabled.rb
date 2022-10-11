require_relative './recording_methods'

module AppMap
  # Detects whether AppMap recording should be enabled. This test can be performed generally, or for
  # a particular recording method. Recording can be enabled explicitly, for example via APPMAP=true,
  # or it can be enabled implicitly, by running in a dev or test web application environment. Recording
  # can also disabled explicitly, using environment variables.
  class DetectEnabled
    @@detected_for_method = {}

    class << self
      def clear_cache
        @@detected_for_method = {}
      end
    end

    def initialize(recording_method)
      @recording_method = recording_method
    end

    def enabled?
      unless @@detected_for_method[@recording_method].nil?
        return @@detected_for_method[@recording_method]
      end

      raise "Unrecognized recording method: #{@recording_method}" if @recording_method && !AppMap::RECORDING_METHODS.member?(@recording_method)

      message, enabled, enabled_by_env = detect_enabled

      @@detected_for_method[@recording_method] = enabled

      if @recording_method
        if enabled && enabled_by_app_env?
          warn AppMap::Util.color("AppMap #{@recording_method.nil? ? '' : "#{@recording_method} "}recording is enabled because #{message}", :magenta)
        end
      end

      enabled
    end

    def detect_enabled
      detection_functions = %i[
        globally_disabled?
        recording_method_disabled?
        enabled_by_testing?
        enabled_by_app_env?
        recording_method_enabled?
        globally_enabled?
      ]

      message, enabled = []
      while enabled.nil? && !detection_functions.empty?
        message, enabled = method(detection_functions.shift).call
      end

      unless enabled.nil?
        _, enabled_by_env = enabled_by_app_env?
        return [ message, enabled, enabled_by_env ]
      else
        return [ 'it is not enabled by any configuration or framework', false, false ]
      end
    end

    def enabled_by_testing?
      if %i[rspec minitest cucumber].member?(@recording_method)
        [ "running tests with #{@recording_method}", true ]
      end
    end

    def enabled_by_app_env?
      env_name, app_env = detect_app_env
      if @recording_method.nil?
        return [ "#{env_name} is '#{app_env}'", true ] if %w[test development].member?(app_env)
      end

      if %i[remote requests].member?(@recording_method)
        return [ "#{env_name} is '#{app_env}'", true ] if app_env == 'development'
      end
    end

    def detect_app_env
      if rails_env
        return [ 'RAILS_ENV', rails_env ]
      elsif ENV['APP_ENV']
        return [ 'APP_ENV', ENV['APP_ENV']]
      end
    end

    def globally_enabled?
      # Don't auto-enable request recording in the 'test' environment, because users probably don't want
      # AppMaps of both test cases and requests. Requests recording can always be enabled by APPMAP_RECORD_REQUESTS=true.
      requests_recording_in_test = -> () { [ :requests ].member?(@recording_method) && detect_app_env == 'test' }
      [ 'APPMAP=true', true ] if ENV['APPMAP'] == 'true' && !requests_recording_in_test.()
    end

    def globally_disabled?
      [ 'APPMAP=false', false ] if ENV['APPMAP'] == 'false'
    end

    def recording_method_disabled?
      return false unless @recording_method

      env_var = [ 'APPMAP', 'RECORD', @recording_method.upcase ].join('_')
      [ "#{[ 'APPMAP', 'RECORD', @recording_method.upcase ].join('_')}=false", false ] if ENV[env_var] == 'false'
    end

    def recording_method_enabled?
      return false unless @recording_method

      env_var = [ 'APPMAP', 'RECORD', @recording_method.upcase ].join('_')
      [ "#{[ 'APPMAP', 'RECORD', @recording_method.upcase ].join('_')}=true", true ] if ENV[env_var] == 'true'
    end

    def rails_env
      return Rails.env if defined?(::Rails::Railtie)

      return ENV['RAILS_ENV']
    end
  end
end

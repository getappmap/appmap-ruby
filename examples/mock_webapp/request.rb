module MockWebapp
  RequestStruct = Struct.new(:params)

  # Mock request.
  # @appmap
  class Request < RequestStruct
    # @appmap
    def initialize(*args)
      super
    end
  end
end

module MockWebapp
  # Mock controller.
  # @appmap
  class Controller
    @controller = nil

    class << self
      # Singleton factory method.
      #
      # @appmap
      def instance
        @controller ||= Controller.new
      end
    end

    # @appmap
    def process(request)
      id = request.params[:id]
      user = User.find(id)
      user.to_h
    end
  end
end

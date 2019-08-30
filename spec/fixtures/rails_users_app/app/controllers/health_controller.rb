class HealthController < ActionController::API
  def show
    render nothing: true, status: 204
  end
end

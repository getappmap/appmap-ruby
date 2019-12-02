class HealthController < ApplicationController
  def show
    render nothing: true, status: 204
  end
end

class UsersController < ApplicationController
  def create
    user = User.new(params[:login], params[:password])

    render nothing: true, status: 422 and return unless user.valid?

    render json: user, status: 201
  end
end

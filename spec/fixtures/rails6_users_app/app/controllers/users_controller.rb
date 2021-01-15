class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def show
    if (@user = User[login: params[:id]])
      render plain: @user
    else
      render plain: 'Not found', status: 404
    end
  end
end

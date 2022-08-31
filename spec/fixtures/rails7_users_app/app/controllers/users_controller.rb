class UsersController < ApplicationController
  def index
    @users = User.all
  end

  def show
    find_user = lambda do |id|
      if User.respond_to?(:[])
        User[login: id]
      else
        User.find_by_login!(id)
      end
    end

    if (@user = find_user.(params[:id]))
      render plain: @user
    else
      render plain: 'Not found', status: 404
    end
  end
end

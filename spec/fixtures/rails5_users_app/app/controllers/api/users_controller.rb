module Api
  class UsersController < ActionController::API
    def index
      @users = User.all
      render json: @users
    end

    def create
      params = self.params.key?(:user) ? self.params[:user] : self.params
      
      @user = build_user(params.slice(:login).to_unsafe_h)
      unless @user.valid?
        error = {
          code: 'invalid',
          target: 'User',
          message: @user.errors.full_messages.join(', '),
          details: @user.errors.map { |k, v| { code: 'invalid', target: k, message: Array(v).join(', ') } }
        }
        return render json: error, status: :unprocessable_entity
      end
      @user.save
      render json: @user, status: :created
    end

    def build_user(params)
      User.new(params)
    end
  end
end

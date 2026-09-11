class Auth::SessionsController < ApplicationController
  # POST /auth/login  { "email": ..., "password": ... }
  def create
    user = User.find_by(email: params[:email])
    unless user&.authenticate(params[:password])
      return render json: { error: "invalid_credentials" }, status: :unauthorized
    end

    user.update!(api_token: User.generate_token)
    render json: { user: UserSerializer.serialize(user), api_token: user.api_token }
  end

  # DELETE /auth/logout — rotate the token so the old one stops working.
  def destroy
    current_user&.update!(api_token: User.generate_token)
    head :no_content
  end
end

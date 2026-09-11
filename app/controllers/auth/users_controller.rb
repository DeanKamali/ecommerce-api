class Auth::UsersController < ApplicationController
  before_action :authenticate_user!

  # GET /auth/me
  def show
    render json: { user: UserSerializer.serialize(current_user) }
  end

  # PATCH /auth/me  { "name": ..., "email": ..., "password": ... }
  def update
    attrs = params.permit(:name, :email, :password)
    if current_user.update(attrs)
      render json: { user: UserSerializer.serialize(current_user) }
    else
      render json: { errors: current_user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  # DELETE /auth/me
  def destroy
    current_user.destroy!
    head :no_content
  end
end

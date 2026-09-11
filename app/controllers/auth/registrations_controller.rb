class Auth::RegistrationsController < ApplicationController
  # POST /auth/register  { "email": ..., "password": ..., "name": ... }
  def create
    attrs = params.permit(:email, :name, :password)

    user = User.create!(
      email: attrs[:email],
      name: attrs[:name],
      password: attrs[:password],
      api_token: User.generate_token
    )

    render json: { user: UserSerializer.serialize(user), api_token: user.api_token },
           status: :created
  end
end

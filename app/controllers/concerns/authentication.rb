module Authentication
  extend ActiveSupport::Concern

  def current_user
    @current_user ||= find_user_by_token
  end

  # Halt the filter chain with 401 when no user is authenticated.
  def authenticate_user!
    return if current_user

    render json: { error: "unauthorized", message: "authentication required" }, status: :unauthorized
  end

  # Halt with 401 when unauthenticated, or 403 when authenticated but not an
  # admin.
  def require_admin!
    return if current_user&.admin?

    if current_user
      render json: { error: "forbidden", message: "admin privileges required" }, status: :forbidden
    else
      render json: { error: "unauthorized", message: "authentication required" }, status: :unauthorized
    end
  end

  private

  def find_user_by_token
    token = bearer_token
    return nil if token.blank?

    User.find_by(api_token: token)
  end

  def bearer_token
    header = request.headers["Authorization"].to_s.strip
    return nil unless header.start_with?("Bearer ")

    header.delete_prefix("Bearer ").strip.presence
  end
end

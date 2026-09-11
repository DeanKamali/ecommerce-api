class ErrorsController < ApplicationController
  def not_found
    render json: { error: "not_found", message: "unknown route" }, status: :not_found
  end
end

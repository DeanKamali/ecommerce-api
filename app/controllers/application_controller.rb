class ApplicationController < ActionController::API
  include Authentication

  rescue_from ActiveRecord::RecordNotFound, with: :render_not_found
  rescue_from ActiveRecord::RecordInvalid, with: :render_validation_error
  rescue_from ActionController::ParameterMissing, with: :render_param_error
 rescue_from Order::InsufficientStock, with: :render_stock_error
 rescue_from ActionController::RoutingError, with: :render_not_found

  private

  def render_not_found(error)
    model = error.respond_to?(:model) && error.model.is_a?(Class) ? error.model : nil
    message = model ? "#{model.name.underscore} not found" : error.message
    render json: { error: "not_found", message: message }, status: :not_found
  end

  def render_validation_error(error)
    record = error.record
    render json: {
      error: "validation_failed",
      record: record.class.name.underscore,
      errors: record.errors.full_messages
    }, status: :unprocessable_entity
  end

  def render_param_error(error)
    render json: { error: "bad_request", message: "missing parameter: #{error.param}" },
      status: :bad_request
  end

  def render_stock_error(error)
    render json: { error: "insufficient_stock", message: error.message },
      status: :unprocessable_entity
  end
end

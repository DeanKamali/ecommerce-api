class OrdersController < ApplicationController
  include Pagination

  before_action :authenticate_user!
  before_action :set_order, only: %i[show update destroy cancel]

  def index
    scope = current_user.orders.includes(:order_items).order(created_at: :desc)
    scope = scope.where(status: params[:status]) if params[:status].present?
    records, meta = paginate(scope)
    render json: {
      data: records.map { |o| OrderSerializer.summary(o) },
      meta: meta
    }
  end

  def show
    render json: OrderSerializer.serialize(@order)
  end

  # Create an order directly:
  #   { "order": { "customer_name": ..., "email": ..., "items": [
  #       { "catalog_item_id": 1, "variant_id": 2, "quantity": 1 } ] } }
  def create
    order_attrs = params.require(:order).permit(:customer_name, :email, :shipping_line1,
      :shipping_city, :shipping_country, :notes, :currency)
    items_params = params.require(:order).require(:items)
    raise ActionController::ParameterMissing.new("items") unless items_params.present?

    items = items_params.map do |p|
      catalog_item = CatalogItem.find(p[:catalog_item_id])
      variant = p[:variant_id].present? ? Variant.find(p[:variant_id]) : nil
      if variant && variant.catalog_item_id != catalog_item.id
        raise ActiveRecord::RecordNotFound, "variant does not belong to this catalog item"
      end
      [catalog_item, variant, (p[:quantity] || 1).to_i]
    end

    order = Order.create_with_items!(items, order_attrs.merge(user: current_user))
    render json: OrderSerializer.serialize(order), status: :created, location: order_url(order)
  end

  # PATCH /orders/:id  { "order": { "status": "confirmed" } }
  def update
    new_status = params.require(:order).require(:status)
    if @order.transition_to(new_status)
      render json: OrderSerializer.serialize(@order)
    else
      render json: { error: "invalid_transition", errors: @order.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  def cancel
    if @order.cancel!
      render json: OrderSerializer.serialize(@order)
    else
      render json: { error: "invalid_transition", errors: @order.errors.full_messages },
        status: :unprocessable_entity
    end
  end

  def destroy
    @order.destroy!
    head :no_content
  end

  private

  def set_order
    @order = current_user.orders.includes(:order_items, :cart).find(params[:id])
  end
end

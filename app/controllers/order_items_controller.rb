class OrderItemsController < ApplicationController
  before_action :authenticate_user!
  def index
    order = current_user.orders.find(params[:order_id])
    render json: { data: order.order_items.order(created_at: :asc).map { |oi| OrderSerializer.item(oi) } }
  end
end

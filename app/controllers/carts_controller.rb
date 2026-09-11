class CartsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cart, only: %i[show destroy checkout]

  def index
    carts = current_user.carts.order(updated_at: :desc).limit(50)
    render json: { data: carts.map { |c| CartSerializer.summary(c) } }
  end

  def create
    attrs = params[:cart]&.permit(:currency)&.to_h || {}
    cart = current_user.carts.create!(attrs)
    render json: CartSerializer.serialize(cart), status: :created, location: cart_url(cart)
  end

  def show
    render json: CartSerializer.serialize(@cart)
  end

  def destroy
    @cart.destroy!
    head :no_content
  end

  # Convert the cart into an order. Accepts order/customer attributes.
  def checkout
    attrs = params[:order]&.permit(:customer_name, :email, :shipping_line1, :shipping_city,
      :shipping_country, :notes)&.to_h || {}

    items = @cart.cart_items.map do |ci|
      [ci.catalog_item, ci.variant, ci.quantity]
    end

    order = Order.create_with_items!(items, attrs.merge(cart: @cart, user: current_user))
    render json: OrderSerializer.serialize(order), status: :created, location: order_url(order)
  end

  private

  def set_cart
    @cart = current_user.carts.find(params[:id])
  end
end

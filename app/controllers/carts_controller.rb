class CartsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cart, only: %i[show destroy checkout coupon]

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
  # Line items keep the unit prices locked in when they were added, and the
  # applied coupon (if any) is snapshotted onto the order.
  def checkout
    attrs = params[:order]&.permit(:customer_name, :email, :shipping_line1, :shipping_city,
      :shipping_country, :notes)&.to_h || {}

    items = @cart.cart_items.map do |ci|
      [ci.catalog_item, ci.variant, ci.quantity, ci.unit_price_cents]
    end

    order = Order.create_with_items!(items, attrs.merge(
      cart: @cart,
      user: current_user,
      coupon_code: @cart.applied_coupon&.code,
      discount_cents: @cart.discount_cents
    ))
    render json: OrderSerializer.serialize(order), status: :created, location: order_url(order)
  end

  # POST /carts/:id/coupon  { "coupon": { "code": "SAVE10" } }
  # Apply a coupon to the cart (replaces any previously applied one).
  def coupon
    code = params.dig(:coupon, :code).to_s
    raise ActionController::ParameterMissing.new(:code) if code.blank?

    @cart.apply_coupon!(code)
    render json: CartSerializer.serialize(@cart)
  end

  private

  def set_cart
    @cart = current_user.carts.find(params[:id])
  end
end

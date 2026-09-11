class CouponsController < ApplicationController
  before_action :require_admin!
  before_action :set_coupon, only: %i[show update destroy]

  # GET /coupons
  def index
    coupons = Coupon.order(created_at: :desc).limit(100)
    render json: { data: coupons.map { |c| CouponSerializer.serialize(c) } }
  end

  # GET /coupons/:id
  def show
    render json: CouponSerializer.serialize(@coupon)
  end

  # POST /coupons
  #   { "coupon": { "code": "SAVE10", "kind": "percent", "value": 10,
  #                  "min_subtotal_cents": 1000, "valid_until": "..." } }
  def create
    coupon = Coupon.create!(coupon_params)
    render json: CouponSerializer.serialize(coupon), status: :created
  end

  # PATCH /coupons/:id
  def update
    @coupon.update!(coupon_params)
    render json: CouponSerializer.serialize(@coupon)
  end

  # DELETE /coupons/:id
  def destroy
    @coupon.destroy!
    head :no_content
  end

  private

  def set_coupon
    @coupon = Coupon.find(params[:id])
  end

  def coupon_params
    params.require(:coupon).permit(:code, :kind, :value, :min_subtotal_cents,
                                   :valid_from, :valid_until, :max_redemptions, :active)
  end
end

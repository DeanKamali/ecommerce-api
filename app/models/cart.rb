class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, -> { order(position: :asc) }, dependent: :destroy
  belongs_to :applied_coupon, class_name: "Coupon", optional: true

  validates :token, presence: true, uniqueness: true
  validates :currency, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/ }

  before_validation :set_token, on: :create

  def subtotal_cents
    cart_items.sum { |ci| ci.unit_price_cents * ci.quantity }
  end

  def discount_cents
    applied_coupon&.discount_cents(subtotal_cents) || 0
  end

  def total_cents
    [subtotal_cents - discount_cents, 0].max
  end

  # Apply a coupon by code (case-insensitive). Raises ActiveRecord::RecordNotFound
  # for unknown codes and Coupon::NotApplicable when the coupon can't be used.
  def apply_coupon!(code, now: Time.current)
    coupon = Coupon.find_by!(code: code.to_s.strip.upcase)
    coupon.apply_to!(self, now: now)
    coupon
  end

  # Remove the applied coupon (if any) and release its redemption.
  def remove_applied_coupon!
    coupon = applied_coupon
    self.applied_coupon = nil
    save!
    coupon&.decrement!(:used_count)
  end

  private

  def set_token
    self.token ||= SecureRandom.uuid
    self.currency = currency.to_s.upcase.presence || "USD"
  end
end

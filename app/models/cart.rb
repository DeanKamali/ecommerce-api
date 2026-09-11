class Cart < ApplicationRecord
  belongs_to :user
  has_many :cart_items, -> { order(position: :asc) }, dependent: :destroy

  validates :token, presence: true, uniqueness: true
  validates :currency, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/ }

  before_validation :set_token, on: :create

  def subtotal_cents
    cart_items.sum { |ci| ci.unit_price_cents * ci.quantity }
  end

  def total_cents
    subtotal_cents
  end

  private

  def set_token
    self.token ||= SecureRandom.uuid
    self.currency = currency.to_s.upcase.presence || "USD"
  end
end

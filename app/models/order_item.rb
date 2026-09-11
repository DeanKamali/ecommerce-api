class OrderItem < ApplicationRecord
  belongs_to :order
  belongs_to :catalog_item
  belongs_to :variant, optional: true

  validates :name, presence: true
  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  before_validation do
    self.line_total_cents = unit_price_cents * quantity
  end
end

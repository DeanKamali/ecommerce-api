class CartItem < ApplicationRecord
  belongs_to :cart
  belongs_to :catalog_item
  belongs_to :variant, optional: true

  validates :quantity, numericality: { greater_than: 0, only_integer: true }
  validates :unit_price_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :variant_belongs_to_item

  def line_total_cents
    unit_price_cents * quantity
  end

  private

  def variant_belongs_to_item
    if variant && variant.catalog_item_id != catalog_item_id
      errors.add(:variant_id, "does not belong to this catalog item")
    end
  end
end

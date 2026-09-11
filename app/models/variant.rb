class Variant < ApplicationRecord
  belongs_to :catalog_item
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error

  before_validation { self.options = {} if options.nil? }
  validates :name, presence: true
  validates :sku, presence: true, uniqueness: true, format: { with: /\A[\w-]+\z/ }
  validates :price_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validate :catalog_item_allows_variants

  private

  def catalog_item_allows_variants
    if catalog_item.is_a?(Service)
      errors.add(:catalog_item_id, "services cannot have variants")
    end
  end
end

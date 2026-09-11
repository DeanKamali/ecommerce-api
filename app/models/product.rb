class Product < CatalogItem
  validates :sku, format: { with: /\A[\w-]+\z/ }, allow_blank: true
  validates :stock_quantity, numericality: { greater_than_or_equal_to: 0, only_integer: true }

  def unit_price_cents_for(variant)
    variant&.price_cents || price_cents
  end
end

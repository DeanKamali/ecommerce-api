module VariantSerializer
  def self.serialize(variant)
    {
      id: variant.id,
      name: variant.name,
      sku: variant.sku,
      price: { cents: variant.price_cents, currency: variant.catalog_item&.currency || "USD" },
      stock_quantity: variant.stock_quantity,
      options: variant.options
    }
  end
end

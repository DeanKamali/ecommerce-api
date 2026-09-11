module CartSerializer
  def self.serialize(cart)
    {
      id: cart.id,
      user_id: cart.user_id,
      token: cart.token,
      currency: cart.currency,
      items: cart.cart_items.map { |ci| item(ci) },
      subtotal_cents: cart.subtotal_cents,
      total_cents: cart.total_cents,
      updated_at: cart.updated_at
    }
  end

  def self.summary(cart)
    {
      id: cart.id,
      user_id: cart.user_id,
      token: cart.token,
      currency: cart.currency,
      items_count: cart.cart_items.count,
      subtotal_cents: cart.subtotal_cents,
      updated_at: cart.updated_at
    }
  end

  def self.item(cart_item)
    {
      id: cart_item.id,
      catalog_item: {
        id: cart_item.catalog_item.id,
        type: cart_item.catalog_item.type.underscore,
        name: cart_item.catalog_item.name
      },
      variant: cart_item.variant && {
        id: cart_item.variant.id,
        name: cart_item.variant.name,
        sku: cart_item.variant.sku
      },
      quantity: cart_item.quantity,
      unit_price_cents: cart_item.unit_price_cents,
      line_total_cents: cart_item.line_total_cents
    }
  end
end

module OrderSerializer
  def self.serialize(order)
    {
      id: order.id,
      user_id: order.user_id,
      number: order.number,
      status: order.status,
      currency: order.currency,
      subtotal_cents: order.subtotal_cents,
      discount_cents: order.discount_cents,
      coupon_code: order.coupon_code,
      total_cents: order.total_cents,
      customer: {
        name: order.customer_name,
        email: order.email
      },
      shipping: {
        line1: order.shipping_line1,
        city: order.shipping_city,
        country: order.shipping_country
      },
      notes: order.notes,
      items: order.order_items.map { |oi| item(oi) },
      created_at: order.created_at,
      updated_at: order.updated_at
    }
  end

  def self.summary(order)
    {
      id: order.id,
      user_id: order.user_id,
      number: order.number,
      status: order.status,
      currency: order.currency,
      subtotal_cents: order.subtotal_cents,
      discount_cents: order.discount_cents,
      total_cents: order.total_cents,
      customer_name: order.customer_name,
      items_count: order.order_items.count,
      created_at: order.created_at
    }
  end

  def self.item(order_item)
    {
      id: order_item.id,
      catalog_item_id: order_item.catalog_item_id,
      name: order_item.name,
      variant: order_item.variant && {
        id: order_item.variant.id,
        name: order_item.variant_name
      },
      quantity: order_item.quantity,
      unit_price_cents: order_item.unit_price_cents,
      line_total_cents: order_item.line_total_cents
    }
  end
end

module CatalogItemSerializer
  def self.serialize(item, include_reviews: false)
    base = {
      id: item.id,
      type: item.type.underscore,
      name: item.name,
      slug: item.slug,
      description: item.description,
      category: item.category && CategorySerializer.serialize(item.category),
      price: { cents: item.price_cents, currency: item.currency },
      active: item.active,
      featured: item.featured,
      in_stock: item.in_stock?,
      rating: {
        average: item.average_rating,
        count: item.respond_to?(:reviews_count) ? item.reviews_count : item.reviews.count
      },
      created_at: item.created_at
    }

    base.merge!(type_fields(item))
    base[:reviews] = item.reviews.map { |r| ReviewSerializer.serialize(r) } if include_reviews
    base
  end

  def self.type_fields(item)
    case item
    when Product
      {
        sku: item.sku,
        stock_quantity: item.stock_quantity,
        track_inventory: item.track_inventory,
        variants: item.variants.map { |v| VariantSerializer.serialize(v) }
      }
    when Service
      {
        duration_minutes: item.duration_minutes,
        bookable: item.bookable,
        max_capacity: item.max_capacity
      }
    else
      {}
    end
  end
end

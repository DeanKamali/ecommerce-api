class CatalogItem < ApplicationRecord
  has_many :variants, dependent: :destroy
  has_many :reviews, dependent: :destroy
  has_many :cart_items, dependent: :destroy
  has_many :order_items, dependent: :restrict_with_error
  belongs_to :category, optional: true

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true
  validates :price_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }
  validates :currency, length: { is: 3 }, format: { with: /\A[A-Z]{3}\z/ }

  before_validation do
    self.slug = slug&.presence&.parameterize || name&.parameterize
    self.currency = currency.to_s.upcase.presence || "USD"
  end

  scope :active, -> { where(active: true) }
  scope :featured, -> { where(featured: true) }
  scope :search, lambda { |q|
    q.present? ? where("catalog_items.name LIKE :q OR catalog_items.description LIKE :q",
      q: "%#{sanitize_sql_like(q)}%") : all
  }
  scope :in_price_range, lambda { |min_cents, max_cents|
    rel = all
    rel = rel.where("catalog_items.price_cents >= ?", min_cents) if min_cents
    rel = rel.where("catalog_items.price_cents <= ?", max_cents) if max_cents
    rel
  }
  scope :sorted, lambda { |key|
    case key
    when "price_asc" then order(price_cents: :asc)
    when "price_desc" then order(price_cents: :desc)
    when "name" then order(name: :asc)
    when "rating" then left_joins(:reviews).group("catalog_items.id")
      .order(Arel.sql("AVG(reviews.rating) DESC")).order(id: :asc)
    else order(created_at: :desc)
    end
  }

  def in_stock?
    case self
    when Service
      bookable?
    when Product
      return true unless track_inventory?
      if variants.exists?
        variants.any? { |v| v.stock_quantity.to_i.positive? }
      else
        stock_quantity.to_i.positive?
      end
    else
      true
    end
  end

  def average_rating
    if respond_to?(:avg_rating) && avg_rating
      avg_rating.round(2)
    else
      reviews.average(:rating)&.round(2) || 0.0
    end
  end
end

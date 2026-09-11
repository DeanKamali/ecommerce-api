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
  validates :sale_price_cents, numericality: { greater_than_or_equal_to: 0, only_integer: true }, allow_nil: true
  validates :markdown_step_days, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :markdown_step_percent, numericality: { in: 0..100, only_integer: true }, allow_nil: true
  validates :max_discount_percent, numericality: { in: 0..100, only_integer: true }, allow_nil: true
  validate :sale_price_is_lower_than_list
  validate :sale_window_is_sane

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

  # --- Sale & markdown pricing -------------------------------------------------
  # Effective price: variant price (or list price), overridden by the sale
  # price while the sale window is open, then reduced further by the
  # markdown percentage that escalates with time spent unsold.

  def on_sale?(now = Time.current)
    sale_price_cents.present? &&
      (sale_starts_at.nil? || sale_starts_at <= now) &&
      (sale_ends_at.nil? || sale_ends_at > now)
  end

  # An item is "unsold" when no confirmed/shipped/delivered order contains
  # it (any of its variants counts).
  def unsold?(now = Time.current)
    !Order.joins(:order_items)
          .where(status: %w[confirmed shipped delivered])
          .where(order_items: { catalog_item_id: id })
          .exists?
  end

  # Discount percent (0..max_discount_percent) applied because the item has
  # sat unsold since it was created: +markdown_step_percent every
  # markdown_step_days.
  def markdown_discount_percent(now = Time.current)
    step_days = markdown_step_days.to_i
    step_percent = markdown_step_percent.to_i
    cap = max_discount_percent.to_i
    return 0 if step_days.zero? || step_percent.zero? || cap.zero?
    return 0 unless unsold?(now)

    elapsed_days = [(now - created_at) / 86_400, 0].floor
    [elapsed_days / step_days * step_percent, cap].min
  end

  def current_price_cents(variant = nil, now = Time.current)
    price = on_sale?(now) ? sale_price_cents : (variant&.price_cents || price_cents)
    percent = markdown_discount_percent(now)
    return price if percent.zero?

    price * (100 - percent) / 100
  end

  def sale_price_is_lower_than_list
    return unless sale_price_cents.present?

    errors.add(:sale_price_cents, "must be lower than the list price") if sale_price_cents >= price_cents.to_i
  end

  def sale_window_is_sane
    return if sale_starts_at.nil? || sale_ends_at.nil?

    errors.add(:sale_ends_at, "must be after sale_starts_at") if sale_ends_at <= sale_starts_at
  end
end

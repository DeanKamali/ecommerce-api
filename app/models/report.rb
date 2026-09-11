# A precomputed KPI snapshot for one calendar week or month, produced by
# ReportJob (recurring in production via config/recurring.yml).
class Report < ApplicationRecord
  PERIODS = %w[weekly monthly].freeze

  validates :period, inclusion: { in: PERIODS }
  validates :period_start, :period_end, presence: true
  validates :order_count, :revenue_cents, :average_order_value_cents,
            :discount_cents, :new_customers,
            numericality: { greater_than_or_equal_to: 0 }

  scope :latest, ->(n = 20) { order(created_at: :desc, id: :desc).limit(n) }

  # Compute the snapshot for the period containing `as_of`.
  # Cancelled orders are excluded from revenue and customer counts.
  def self.generate(period, as_of: Time.current)
    unless PERIODS.include?(period)
      raise ArgumentError, "period must be one of: #{PERIODS.join(", ")}"
    end

    start = period == "weekly" ? as_of.beginning_of_week : as_of.beginning_of_month
    finish = start + (period == "weekly" ? 1.week : 1.month)

    orders = Order.where.not(status: "cancelled").where(created_at: start...finish)
    revenue = orders.sum(:total_cents)
    count = orders.count

    top = OrderItem.where(order: orders)
                  .joins(:catalog_item)
                  .group("catalog_items.id")
                  .select(
                    "catalog_items.id",
                    "catalog_items.name",
                    "catalog_items.type",
                    "SUM(order_items.quantity) AS quantity",
                    "SUM(order_items.line_total_cents) AS revenue_cents"
                  )
                  .order("SUM(order_items.line_total_cents) DESC")
                  .limit(10)
                  .map do |row|
                    {
                      id: row.id,
                      name: row.name,
                      type: row.type.to_s.underscore,
                      quantity: row.quantity.to_i,
                      revenue_cents: row.revenue_cents.to_i
                    }
                  end

    report = find_or_initialize_by(period: period, period_start: start)
    report.assign_attributes(
      period_end: finish,
      order_count: count,
      revenue_cents: revenue,
      average_order_value_cents: count.zero? ? 0 : (revenue / count).round,
      discount_cents: orders.sum(:discount_cents),
      new_customers: orders.distinct.count(:email),
      top_items: top
    )
    report.save!
    report
  end
end

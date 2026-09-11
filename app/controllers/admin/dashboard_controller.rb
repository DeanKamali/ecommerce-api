# Admin-only KPI / dashboard endpoints.
#
#   GET  /admin/overview          live KPI snapshot
#   GET  /admin/reports           precomputed report snapshots (optional ?period=)
#   GET  /admin/reports/:id       a single report
#   GET  /admin/top_items         top catalog items by revenue (optional ?limit=)
#   POST /admin/reports/generate  synchronously (re)generate a report { "period": "weekly"|"monthly" }
class Admin::DashboardController < ApplicationController
  include Pagination

  LOW_STOCK_THRESHOLD = 5

  before_action :require_admin!

  # GET /admin/overview
  def overview
    active = Order.where.not(status: :cancelled)
    active_count = active.count
    revenue_cents = active.sum(:total_cents)

    render json: {
      currency: default_currency,
      orders: {
        total: Order.count,
        active: active_count,
        by_status: Order.group(:status).count
      },
      revenue_cents: revenue_cents,
      average_order_value_cents: active_count.zero? ? 0 : revenue_cents / active_count,
      discounts_cents: active.sum(:discount_cents),
      customers: Order.distinct.count(:email),
      catalog: {
        total: CatalogItem.count,
        products: Product.count,
        services: Service.count,
        low_stock: Product.where(track_inventory: true)
                          .where("stock_quantity <= ?", LOW_STOCK_THRESHOLD)
                          .count
      },
      coupons: {
        total: Coupon.count,
        active: Coupon.where(active: true).count
      },
      periods: {
        this_week: period_stats(1.week.ago),
        this_month: period_stats(1.month.ago)
      },
      last_order_at: Order.order(created_at: :desc).limit(1).pluck(:created_at).first
    }
  end

  # GET /admin/reports
  def reports
    scope = Report.order(created_at: :desc)
    scope = scope.where(period: params[:period]) if params[:period].present?
    records, meta = paginate(scope)
    render json: { data: records.map { |r| ReportSerializer.serialize(r) }, meta: meta }
  end

  # GET /admin/reports/:id
  def report
    render json: ReportSerializer.serialize(Report.find(params[:id]))
  end

  # GET /admin/top_items
  def top_items
    limit = params.fetch(:limit, 10).to_i.clamp(1, 50)
    rows = OrderItem.joins(:order)
                    .merge(Order.where.not(status: :cancelled))
                    .group("order_items.catalog_item_id")
                    .select(
                      "order_items.catalog_item_id",
                      "SUM(order_items.quantity) AS total_quantity",
                      "SUM(order_items.line_total_cents) AS total_revenue"
                    )
                    .order("total_revenue DESC")
                    .limit(limit)

    items = CatalogItem.where(id: rows.map(&:catalog_item_id)).index_by(&:id)
    data = rows.filter_map do |row|
      item = items[row.catalog_item_id]
      next if item.nil?

      {
        id: item.id,
        name: item.name,
        type: item.type.underscore,
        quantity: row.total_quantity,
        revenue_cents: row.total_revenue
      }
    end
    render json: { data: data, limit: limit }
  end

  # POST /admin/reports/generate
  def generate
    period = params.require(:period)
    unless Report::PERIODS.include?(period)
      render json: { error: "bad_request", message: "period must be one of: #{Report::PERIODS.join(', ')}" },
             status: :bad_request
      return
    end

    report = Report.generate(period)
    render json: ReportSerializer.serialize(report), status: :created
  end

  private

  def default_currency
    Order.order(created_at: :desc).limit(1).pluck(:currency).first || "USD"
  end

  def period_stats(since)
    active = Order.where.not(status: :cancelled).where(created_at: since..)
    {
      orders: active.count,
      revenue_cents: active.sum(:total_cents)
    }
  end
end

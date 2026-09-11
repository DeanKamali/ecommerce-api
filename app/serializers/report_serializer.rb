# Serializes a precomputed Report snapshot for the admin dashboard.
module ReportSerializer
  def self.serialize(report)
    {
      id: report.id,
      period: report.period,
      period_start: report.period_start,
      period_end: report.period_end,
      order_count: report.order_count,
      revenue_cents: report.revenue_cents,
      average_order_value_cents: report.average_order_value_cents,
      discount_cents: report.discount_cents,
      new_customers: report.new_customers,
      top_items: report.top_items,
      created_at: report.created_at,
      updated_at: report.updated_at
    }
  end
end

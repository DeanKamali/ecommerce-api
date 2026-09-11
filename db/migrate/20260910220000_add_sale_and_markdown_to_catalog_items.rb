class AddSaleAndMarkdownToCatalogItems < ActiveRecord::Migration[8.1]
  def change
    # Time-limited sale: an item sells at `sale_price_cents` while the window
    # is open (either bound may be nil for an open-ended window).
    add_column :catalog_items, :sale_price_cents, :integer
    add_column :catalog_items, :sale_starts_at, :datetime
    add_column :catalog_items, :sale_ends_at, :datetime

    # Escalating markdown for unsold items: every `markdown_step_days` the
    # effective price drops by another `markdown_step_percent`, capped at
    # `max_discount_percent` (0 = feature disabled).
    add_column :catalog_items, :markdown_step_days, :integer
    add_column :catalog_items, :markdown_step_percent, :integer, default: 0
    add_column :catalog_items, :max_discount_percent, :integer, default: 0
  end
end

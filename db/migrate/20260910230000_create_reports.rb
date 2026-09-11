class CreateReports < ActiveRecord::Migration[8.1]
  def change
    create_table :reports do |t|
      t.string :period, null: false # "weekly" | "monthly"
      t.datetime :period_start, null: false
      t.datetime :period_end, null: false

      t.integer :order_count, default: 0, null: false
      t.bigint :revenue_cents, default: 0, null: false
      t.integer :average_order_value_cents, default: 0, null: false
      t.bigint :discount_cents, default: 0, null: false
      t.integer :new_customers, default: 0, null: false

      # [{ id, name, type, quantity, revenue_cents }] — top 10 by revenue.
      t.json :top_items, default: [], null: false

      t.timestamps
    end

    add_index :reports, %i[period period_start], unique: true
    add_index :reports, %i[period created_at]
  end
end

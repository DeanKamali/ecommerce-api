class CreateOrderItems < ActiveRecord::Migration[8.1]
  def change
    create_table :order_items do |t|
      t.references :order, null: false, foreign_key: true
      t.references :catalog_item, null: false, foreign_key: true
      t.references :variant, null: true, foreign_key: true
      t.string :name, null: false
      t.string :variant_name
      t.integer :unit_price_cents, null: false
      t.integer :quantity, null: false, default: 1
      t.integer :line_total_cents, null: false

      t.timestamps
    end
  end
end

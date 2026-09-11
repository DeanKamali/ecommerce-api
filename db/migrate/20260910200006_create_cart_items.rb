class CreateCartItems < ActiveRecord::Migration[8.1]
  def change
    create_table :cart_items do |t|
      t.references :cart, null: false, foreign_key: true
      t.references :catalog_item, null: false, foreign_key: true
      t.references :variant, null: true, foreign_key: true
      t.integer :quantity, null: false, default: 1
      t.integer :unit_price_cents, null: false
      t.integer :position, null: false, default: 0

      t.timestamps
    end
  end
end

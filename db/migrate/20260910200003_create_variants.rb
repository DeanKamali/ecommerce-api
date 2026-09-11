class CreateVariants < ActiveRecord::Migration[8.1]
  def change
    create_table :variants do |t|
      t.references :catalog_item, null: false, foreign_key: true
      t.string :name, null: false
      t.string :sku, null: false
      t.integer :price_cents, null: false
      t.integer :stock_quantity, null: false, default: 0
      t.json :options
      t.timestamps
    end

    add_index :variants, :sku, unique: true
  end
end

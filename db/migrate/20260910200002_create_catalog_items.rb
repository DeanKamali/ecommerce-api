class CreateCatalogItems < ActiveRecord::Migration[8.1]
  def change
    create_table :catalog_items do |t|
      t.string :type, null: false
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :category, null: true, foreign_key: true

      t.integer :price_cents, null: false, default: 0
      t.string :currency, null: false, default: "USD", limit: 3
      t.boolean :active, null: false, default: true
      t.boolean :featured, null: false, default: false

      # Product-specific
      t.string :sku
      t.integer :stock_quantity, default: 0
      t.boolean :track_inventory, default: true

      # Service-specific
      t.integer :duration_minutes
      t.boolean :bookable, default: true
      t.integer :max_capacity

      t.timestamps
    end

    add_index :catalog_items, :slug, unique: true
    add_index :catalog_items, :type
  end
end

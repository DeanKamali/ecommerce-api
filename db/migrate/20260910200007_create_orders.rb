class CreateOrders < ActiveRecord::Migration[8.1]
  def change
    create_table :orders do |t|
      t.string :number, null: false
      t.string :status, null: false, default: "pending"
      t.string :currency, null: false, default: "USD", limit: 3
      t.integer :subtotal_cents, null: false, default: 0
      t.integer :total_cents, null: false, default: 0

      t.string :customer_name
      t.string :email
      t.string :shipping_line1
      t.string :shipping_city
      t.string :shipping_country
      t.text :notes
      t.references :cart, null: true, foreign_key: true

      t.timestamps
    end

    add_index :orders, :number, unique: true
    add_index :orders, :status
  end
end

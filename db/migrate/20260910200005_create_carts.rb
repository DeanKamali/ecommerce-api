class CreateCarts < ActiveRecord::Migration[8.1]
  def change
    create_table :carts do |t|
      t.string :token, null: false
      t.string :currency, null: false, default: "USD", limit: 3

      t.timestamps
    end

    add_index :carts, :token, unique: true
  end
end

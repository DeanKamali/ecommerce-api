class CreateCoupons < ActiveRecord::Migration[8.1]
  def change
    create_table :coupons do |t|
      t.string :code, null: false
      t.string :kind, null: false, default: "percent" # percent | fixed
      t.integer :value, null: false # percent: 1..100, fixed: cents
      t.integer :min_subtotal_cents, default: 0, null: false
      t.datetime :valid_from
      t.datetime :valid_until
      t.integer :max_redemptions # nil = unlimited
      t.integer :used_count, default: 0, null: false
      t.boolean :active, default: true, null: false

      t.timestamps
    end

    add_index :coupons, :code, unique: true
    add_reference :carts, :applied_coupon, foreign_key: { to_table: :coupons }
  end
end

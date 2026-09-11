class AddCouponToOrders < ActiveRecord::Migration[8.1]
  def change
    # Snapshot of the coupon applied at checkout time.
    add_column :orders, :discount_cents, :integer, default: 0, null: false
    add_column :orders, :coupon_code, :string
  end
end

class AddUserIdToCartsOrdersAndReviews < ActiveRecord::Migration[8.1]
  def change
    # Nullable at the DB level so existing rows survive the migration; the
    # models enforce ownership via `belongs_to :user` (required in Rails).
    add_reference :carts, :user, null: true, foreign_key: true
    add_reference :orders, :user, null: true, foreign_key: true
    add_reference :reviews, :user, null: true, foreign_key: true
  end
end

class CreateUsers < ActiveRecord::Migration[8.1]
  def change
    create_table :users do |t|
      t.string :email, null: false
      t.string :name, null: false
      t.string :password_digest, null: false
      t.string :api_token
      t.boolean :admin, null: false, default: false

      t.timestamps
    end

    add_index :users, :email, unique: true
    # SQLite allows multiple NULLs in a unique index, so users without a
    # token (logged out) do not collide.
    add_index :users, :api_token, unique: true
  end
end

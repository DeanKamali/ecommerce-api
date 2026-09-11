class CreateReviews < ActiveRecord::Migration[8.1]
  def change
    create_table :reviews do |t|
      t.references :catalog_item, null: false, foreign_key: true
      t.string :author, null: false
      t.integer :rating, null: false
      t.text :body

      t.timestamps
    end

    add_index :reviews, :rating
  end
end

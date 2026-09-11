class CreateCategories < ActiveRecord::Migration[8.1]
  def change
    create_table :categories do |t|
      t.string :name, null: false
      t.string :slug, null: false
      t.text :description
      t.references :parent, null: true, foreign_key: { to_table: :categories }

      t.timestamps
    end

    add_index :categories, :slug, unique: true
  end
end

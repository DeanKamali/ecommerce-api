class Category < ApplicationRecord
  has_many :catalog_items, dependent: :nullify
  has_many :children, class_name: "Category", foreign_key: :parent_id, dependent: :destroy
  belongs_to :parent, class_name: "Category", optional: true

  validates :name, presence: true, uniqueness: true
  validates :slug, presence: true, uniqueness: true

  before_validation do
    self.slug = slug&.presence&.parameterize || name&.parameterize
  end
end

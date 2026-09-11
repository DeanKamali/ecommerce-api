class Review < ApplicationRecord
  belongs_to :catalog_item
  belongs_to :user

  validates :author, presence: true
  validates :rating, inclusion: { in: 1..5 }
  validates :body, length: { maximum: 2000 }
end

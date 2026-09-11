class Service < CatalogItem
  validates :duration_minutes, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
  validates :max_capacity, numericality: { greater_than: 0, only_integer: true }, allow_nil: true
end

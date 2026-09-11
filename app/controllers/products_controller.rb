class ProductsController < CatalogItems::BaseController
  ScopedClass = Product
  EXTRA_PARAMS = %i[sku stock_quantity track_inventory]
end

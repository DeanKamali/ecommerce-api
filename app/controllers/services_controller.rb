class ServicesController < CatalogItems::BaseController
  ScopedClass = Service
  EXTRA_PARAMS = %i[duration_minutes bookable max_capacity]
end

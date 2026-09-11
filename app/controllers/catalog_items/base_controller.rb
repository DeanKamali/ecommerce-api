class CatalogItems::BaseController < ApplicationController
  include Pagination

  before_action :set_item, only: %i[show update destroy]
  before_action :require_admin!, only: %i[create update destroy]

  # Subclasses override EXTRA_PARAMS with additional permitted attributes.
  EXTRA_PARAMS = []

  def scoped_class
    self.class::ScopedClass
  end

  def index
    scope = scoped_class.active.includes(:category)
    if params[:category].present?
      scope = scope.joins(:category).where(categories: { slug: params[:category] })
    end
    scope = scope.search(params[:q]) if params[:q].present?
    if params[:min_price].present? || params[:max_price].present?
      scope = scope.in_price_range(params[:min_price], params[:max_price])
    end
    scope = scope.featured if ActiveModel::Type::Boolean.new.cast(params[:featured])
    count_scope = scope
    scope = scope.select(
      "catalog_items.*",
      Arel.sql("(SELECT COUNT(*) FROM reviews WHERE reviews.catalog_item_id = catalog_items.id)").as("reviews_count"),
      Arel.sql("(SELECT AVG(rating) FROM reviews WHERE reviews.catalog_item_id = catalog_items.id)").as("avg_rating")
    ).sorted(params[:sort])

    records, meta = paginate(scope, count_scope)
    render json: {
      data: records.map { |i| CatalogItemSerializer.serialize(i) },
      meta: meta
    }
  end

  def show
    item = scoped_class.includes(:category, :variants, :reviews).find(params[:id])
    render json: CatalogItemSerializer.serialize(item, include_reviews: true)
  end

  def create
    item = scoped_class.create!(item_params)
    render json: CatalogItemSerializer.serialize(item), status: :created, location: polymorphic_url(item)
  end

  def update
    @item.update!(item_params)
    render json: CatalogItemSerializer.serialize(@item)
  end

  def destroy
    @item.destroy!
    head :no_content
  end

  private

  def set_item
    @item = scoped_class.find(params[:id])
  end

  def item_params
    params.require(scoped_class.name.underscore.to_sym)
      .permit(:name, :slug, :description, :category_id, :price_cents, :currency, :active, :featured,
        :sale_price_cents, :sale_starts_at, :sale_ends_at,
        :markdown_step_days, :markdown_step_percent, :max_discount_percent,
        *self.class::EXTRA_PARAMS)
  end
end

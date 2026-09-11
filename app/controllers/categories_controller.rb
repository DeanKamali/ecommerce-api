class CategoriesController < ApplicationController
  include Pagination

  before_action :set_category, only: %i[show update destroy]
  before_action :require_admin!, only: %i[create update destroy]

  def index
    scope = Category.includes(:catalog_items).order(name: :asc)
    scope = scope.where(parent_id: params[:parent_id]) if params[:parent_id].present?
    records, meta = paginate(scope)
    render json: {
      data: records.map { |c| CategorySerializer.serialize(c).merge(items_count: c.catalog_items.count) },
      meta: meta
    }
  end

  def show
    render json: CategorySerializer.serialize(@category).merge(
      items: @category.catalog_items.map { |i| CatalogItemSerializer.serialize(i) }
    )
  end

  def create
    category = Category.create!(category_params)
    render json: CategorySerializer.serialize(category), status: :created, location: category_url(category)
  end

  def update
    @category.update!(category_params)
    render json: CategorySerializer.serialize(@category)
  end

  def destroy
    @category.destroy!
    head :no_content
  end

  private

  def set_category
    @category = Category.find(params[:id])
  end

  def category_params
    params.require(:category).permit(:name, :slug, :description, :parent_id)
  end
end

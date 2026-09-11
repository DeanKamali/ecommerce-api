class VariantsController < ApplicationController
  before_action :set_item
  before_action :set_variant, only: %i[show update destroy]
  before_action :require_admin!, only: %i[create update destroy]

  def index
    render json: { data: @item.variants.order(created_at: :asc).map { |v| VariantSerializer.serialize(v) } }
  end

  def show
    render json: VariantSerializer.serialize(@variant)
  end

  def create
    variant = @item.variants.create!(variant_params)
    render json: VariantSerializer.serialize(variant), status: :created,
      location: product_variant_url(@item, variant)
  end

  def update
    @variant.update!(variant_params)
    render json: VariantSerializer.serialize(@variant)
  end

  def destroy
    @variant.destroy!
    head :no_content
  end

  private

  def set_item
    @item = Product.find(params[:product_id])
  end

  def set_variant
    @variant = @item.variants.find(params[:id])
  end

  def variant_params
    params.require(:variant).permit(:name, :sku, :price_cents, :stock_quantity, :options)
  end
end

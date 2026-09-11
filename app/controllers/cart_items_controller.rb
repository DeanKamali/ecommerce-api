class CartItemsController < ApplicationController
  before_action :authenticate_user!
  before_action :set_cart
  before_action :set_item, only: %i[show update destroy]

  def index
    render json: { data: @cart.cart_items.map { |ci| CartSerializer.item(ci) } }
  end

  def show
    render json: CartSerializer.item(@item)
  end

  # Adds a line item, or increments the quantity if the same
  # item+variant is already in the cart.
  def create
    attrs = params.require(:cart_item).permit(:catalog_item_id, :variant_id, :quantity)
    quantity = (attrs[:quantity] || 1).to_i
    raise ActiveRecord::RecordInvalid.new(
      CartItem.new(quantity: quantity)
    ) if quantity < 1
    variant = attrs[:variant_id].present? ? Variant.find(attrs[:variant_id]) : nil
    if variant
      catalog_item = variant.catalog_item
    else
      raise ActionController::ParameterMissing.new(:catalog_item_id) unless attrs[:catalog_item_id].present?
      catalog_item = CatalogItem.find(attrs[:catalog_item_id])
    end

    existing = @cart.cart_items.find_by(catalog_item_id: catalog_item.id, variant_id: attrs[:variant_id])
    if existing
      existing.update!(quantity: existing.quantity + quantity)
    else
      existing = @cart.cart_items.create!(
        catalog_item: catalog_item,
        variant: variant,
        quantity: quantity,
        unit_price_cents: catalog_item.current_price_cents(variant),
        position: @cart.cart_items.count
      )
    end
    render json: CartSerializer.item(existing), status: :created
  end

  # Update quantity (absolute value) or variant.
  def update
    attrs = params.require(:cart_item).permit(:quantity, :variant_id)
    if attrs[:variant_id].present?
      variant = Variant.find(attrs[:variant_id])
      raise ActiveRecord::RecordNotFound, "variant does not belong to this catalog item" if variant.catalog_item_id != @item.catalog_item_id

      attrs = attrs.merge(unit_price_cents: @item.catalog_item.current_price_cents(variant))
    end
    @item.update!(attrs)
    render json: CartSerializer.item(@item)
  end

  def destroy
    @item.destroy!
    head :no_content
  end

  private

  def set_cart
    @cart = current_user.carts.find(params[:cart_id])
  end

  def set_item
    @item = @cart.cart_items.find(params[:id])
  end
end

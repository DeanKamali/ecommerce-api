class ReviewsController < ApplicationController
  include Pagination

  before_action :set_item
  before_action :authenticate_user!, only: %i[create destroy]
  before_action :set_review, only: %i[destroy]
  before_action :authorize_review!, only: %i[destroy]

  def index
    scope = @item.reviews.order(created_at: :desc)
    records, meta = paginate(scope)
    render json: {
      data: records.map { |r| ReviewSerializer.serialize(r) },
      meta: meta,
      average_rating: @item.average_rating
    }
  end

  def create
    attrs = review_params
    attrs[:author] = current_user.name if attrs[:author].blank?
    review = @item.reviews.create!(attrs.merge(user: current_user))
    render json: ReviewSerializer.serialize(review), status: :created,
      location: polymorphic_url([@item, review])
  end

  def destroy
    @review.destroy!
    head :no_content
  end

  private

  def set_item
    @item = CatalogItem.find(params[:product_id] || params[:service_id])
  end

  def set_review
    @review = @item.reviews.find(params[:id])
  end

  def authorize_review!
    return if current_user.admin? || @review.user_id == current_user.id
    render json: { error: "forbidden", message: "you can only delete your own reviews" },
      status: :forbidden
  end

  def review_params
    params.require(:review).permit(:author, :rating, :body)
  end
end

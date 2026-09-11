module ReviewSerializer
  def self.serialize(review)
    {
      id: review.id,
      user_id: review.user_id,
      author: review.author,
      rating: review.rating,
      body: review.body,
      created_at: review.created_at
    }
  end
end

module CategorySerializer
  def self.serialize(category)
    {
      id: category.id,
      name: category.name,
      slug: category.slug,
      description: category.description,
      parent_id: category.parent_id
    }
  end
end

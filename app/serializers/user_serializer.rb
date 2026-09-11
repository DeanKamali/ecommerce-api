module UserSerializer
  def self.serialize(user)
    {
      id: user.id,
      email: user.email,
      name: user.name,
      admin: user.admin,
      created_at: user.created_at
    }
  end
end

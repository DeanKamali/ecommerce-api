class User < ApplicationRecord
  has_secure_password

  has_many :carts, dependent: :destroy
  has_many :orders, dependent: :destroy
  has_many :reviews, dependent: :nullify

  validates :email, presence: true,
    uniqueness: { case_sensitive: false },
    format: { with: URI::MailTo::EMAIL_REGEXP }
  validates :name, presence: true
  validates :password, length: { minimum: 8 }, on: :create

  def regenerate_token!
    update_columns(api_token: self.class.generate_token)
  end

  def self.generate_token
    loop do
      token = SecureRandom.hex(32)
      break token unless exists?(api_token: token)
    end
  end
end

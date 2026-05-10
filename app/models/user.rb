class User < ApplicationRecord
  has_secure_password
  has_many :sessions, dependent: :destroy
  has_many :players, dependent: :nullify

  normalizes :email_address, with: ->(e) { e.strip.downcase }
  normalizes :username, with: ->(u) { u.strip.downcase }

  validates :username, presence: true, uniqueness: { case_sensitive: false }
end

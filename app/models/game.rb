class Game < ApplicationRecord
  has_many :races, dependent: :destroy
  has_many :maps, dependent: :destroy
  has_many :leagues, dependent: :nullify
end

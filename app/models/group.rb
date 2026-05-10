class Group < ApplicationRecord
  belongs_to :league
  
  has_many :group_assignments, dependent: :destroy
  has_many :players, through: :group_assignments
  
  validates :name, presence: true
  validates :tier, presence: true, uniqueness: { scope: :league }
  
  scope :ordered, -> { order(tier: :asc) }
  
  def self.tier_name(tier)
    ("Z".ord - tier).chr
  end
end

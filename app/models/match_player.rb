class MatchPlayer < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :race, optional: true
  
  validates :race, uniqueness: { scope: :match }, if: -> { race_id.present? }
end

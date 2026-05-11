class LeagueMap < ApplicationRecord
  belongs_to :league
  belongs_to :map

  validates :league_id, uniqueness: { scope: :map_id }
  validates :map_id, uniqueness: { scope: :league_id }
end

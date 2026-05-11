class MapBan < ApplicationRecord
  belongs_to :match
  belongs_to :player
  belongs_to :map

  validates :match_id, uniqueness: { scope: [:player_id, :game_number] }
end

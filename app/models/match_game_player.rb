class MatchGamePlayer < ApplicationRecord
  belongs_to :match_game
  belongs_to :match_player
  belongs_to :race, optional: true
  belongs_to :banned_map, class_name: "Map", optional: true

  has_one :player, through: :match_player
  has_one :match,  through: :match_game

  validates :match_player_id, uniqueness: { scope: :match_game_id }
  # Within a single game both players cannot pick the same race.
  validates :race_id, uniqueness: { scope: :match_game_id }, if: -> { race_id.present? }
end

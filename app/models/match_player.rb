class MatchPlayer < ApplicationRecord
  belongs_to :match
  belongs_to :player

  has_many :match_game_players, dependent: :destroy
end

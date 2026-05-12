class MatchGame < ApplicationRecord
  belongs_to :match
  belongs_to :map, optional: true
  belongs_to :winner, class_name: "Player", optional: true

  has_many :match_game_players, dependent: :destroy
  has_many :match_players, through: :match_game_players

  enum :status, [:pending, :races_selected, :map_set, :completed]

  validates :game_number, presence: true, uniqueness: { scope: :match }

  # Returns the MatchGamePlayer row for the given Player in this game, creating
  # it on demand. Used so a freshly-created game always has a slot per player
  # to receive a race pick.
  def player_slot(player)
    match_player = match.match_players.find_by(player: player)
    return nil unless match_player
    match_game_players.find_or_create_by!(match_player: match_player)
  end

  def race_for(player)
    match_game_players
      .joins(:match_player)
      .where(match_players: { player_id: player.id })
      .first&.race
  end
end

class Player < ApplicationRecord
  belongs_to :league
  belongs_to :user, optional: true
  
  has_many :group_assignments, dependent: :destroy
  has_many :groups, through: :group_assignments
  
  has_many :match_players, dependent: :destroy
  has_many :matches, through: :match_players
  has_many :games, through: :matches, source: :games, class_name: "MatchGame"
  has_many :won_games, class_name: "MatchGame", foreign_key: :winner_id, dependent: :nullify, inverse_of: :winner

  has_many :map_bans, dependent: :destroy
  
  validates :name, presence: true
  
  def user_player?(user)
    user_id.present? && user_id == user.id
  end
  
  def my_last_race_in(match)
    match.current_game&.race_for(self)
  end
  
  def my_last_game_won?(match)
    return false unless match.games.any? && match.games.last.winner
    match.games.last.winner == self
  end
  
  # Count of completed matches won by this player (best-of series result, not
  # individual games within a match).
  def wins_count
    completed_matches.count { |m| m.winner == self }
  end

  def losses_count
    completed_matches.count { |m| m.winner.present? && m.winner != self }
  end

  private

  def completed_matches
    matches.where(status: :completed).includes(:match_players, :games)
  end
end

class Player < ApplicationRecord
  belongs_to :league
  belongs_to :user, optional: true
  
  has_many :group_assignments
  has_many :groups, through: :group_assignments
  
  has_many :match_players
  has_many :matches, through: :match_players
  has_many :games, through: :matches, source: :games, class_name: "MatchGame"
  
  validates :name, presence: true
  
  def user_player?(user)
    user_id.present? && user_id == user.id
  end
  
  def my_last_race_in(match)
    match_player = match.match_players.find_by(player: self)
    match_player&.race
  end
  
  def my_last_game_won?(match)
    return false unless match.games.any? && match.games.last.winner
    match.games.last.winner == self
  end
  
  def wins_count
    games.where(winner_id: id).count
  end
  
  def losses_count
    total_games = matches.where(status: :completed).joins(:games).count
    total_games - wins_count
  end
end

class Match < ApplicationRecord
  belongs_to :league
  
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players
  has_many :games, class_name: "MatchGame", dependent: :destroy
  
  accepts_nested_attributes_for :match_players
  
  enum :status, [:pending, :lobby, :races_picking, :races_revealed, :map_picking, :in_progress, :completed]
  
  delegate :game, to: :league
  
  def player1
    match_players.order(:id).first&.player
  end
  
  def player2
    match_players.order(:id).last&.player
  end
  
  def player1_race
    match_players.order(:id).first&.race
  end
  
  def player2_race
    match_players.order(:id).last&.race
  end
  
  def player1_score
    games.where(winner: player1).count
  end
  
  def player2_score
    games.where(winner: player2).count
  end
  
  def current_game
    games.where.not(status: :completed).order(:game_number).first
  end
  
  def winner
    return nil unless completed?
    return player1 if player1_score > player2_score
    return player2 if player2_score > player1_score
    nil
  end
  
  def final_score_for(player)
    return nil unless completed?
    my_score = games.where(winner: player).count
    opponent = players.where.not(id: player.id).first
    opp_score = games.where(winner: opponent).count
    "#{my_score}-#{opp_score}"
  end
  
  def advance_to_race_picking
    # Create first game if none exists
    if games.empty?
      games.create!(game_number: 1, status: :pending)
    end
    update!(status: :races_picking)
  end
  
  def advance_to_race_reveal
    update!(status: :races_revealed)
  end
  
  def advance_to_map_selection
    if current_game
      current_game.update!(status: :races_selected)
    end
    update!(status: :map_picking)
  end
  
  def advance_to_in_progress
    update!(status: :in_progress)
  end
  
  def loser_of_last_game
    # Get the last COMPLETED game, not the newest game
    completed_games = games.where(status: :completed).order(:game_number)
    return nil unless completed_games.any?
    last_game = completed_games.last
    return nil unless last_game&.winner
    players.where.not(id: last_game.winner.id).first
  end
  
  def map_picker
    loser_of_last_game
  end
  
  def available_maps
    return [] unless game
    used_map_ids = games.where.not(map_id: nil).pluck(:map_id)
    game.maps.where.not(id: used_map_ids)
  end
  
  def needs_race_selection?
    # Game 1 needs race selection, subsequent games after map is picked need races
    games.count <= 1
  end
  
  def report_winner(winner_player, _winner_id = nil)
    return unless current_game
    
    current_game.update!(winner: winner_player, status: :completed)
    
    # Check if match is over (2 wins)
    if player1_score == 2 || player2_score == 2
      update!(status: :completed)
    else
      # Create next game and advance to map picking (loser picks map first)
      next_game_number = games.maximum(:game_number).to_i + 1
      games.create!(game_number: next_game_number, status: :pending)
      # Reset race selections for new game
      match_players.update_all(race_id: nil)
      update!(status: :map_picking)
    end
  end
  
  def both_players_ready?
    match_players.all?(&:ready)
  end
  
  def both_races_selected?
    match_players.pluck(:race_id).all?(&:present?)
  end
  
  def my_match_player(player)
    match_players.find_by(player: player)
  end
  
  def opponent_of(player)
    players.where.not(id: player.id).first
  end
  
  def available_races
    return [] unless game
    
    # Winner of previous game can't pick same race
    if games.any? && games.last.winner.present?
      last_winner = games.last.winner
      last_race_id = match_players.find_by(player: last_winner)&.race_id
      if last_race_id.present?
        game.races.where.not(id: last_race_id).to_a
      else
        game.races.to_a
      end
    else
      game.races.to_a
    end
  end
  
  def available_races_for(player)
    available_races
  end
end

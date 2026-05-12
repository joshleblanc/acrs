class Match < ApplicationRecord
  belongs_to :league
  belongs_to :group, optional: true
  
  has_many :match_players, dependent: :destroy
  has_many :players, through: :match_players
  has_many :games, class_name: "MatchGame", dependent: :destroy
  has_many :map_bans, dependent: :destroy
  
  accepts_nested_attributes_for :match_players
  
  enum :status, [:pending, :lobby, :map_banning, :races_picking, :races_revealed, :map_picking, :in_progress, :completed]
  
  delegate :game, to: :league
  
  def player1
    match_players.order(:id).first&.player
  end
  
  def player2
    match_players.order(:id).last&.player
  end
  
  def player1_race
    current_game&.race_for(player1)
  end
  
  def player2_race
    current_game&.race_for(player2)
  end

  # MatchGamePlayer slot for the given Player in the current game (lazily
  # created so a fresh game always has a row to populate).
  def current_game_slot_for(player)
    current_game&.player_slot(player)
  end

  # MatchGamePlayer for the given player in the current game without creating.
  def current_game_player_pick(player)
    return nil unless current_game
    current_game.match_game_players
                .joins(:match_player)
                .find_by(match_players: { player_id: player.id })
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
  
  def advance_to_map_banning
    # Create first game if none exists
    if games.empty?
      # Set the week's default map for game 1
      game = games.create!(game_number: 1, status: :pending)
      week_map = league.map_for_match(self)
      game.update!(map_id: week_map.id) if week_map
      seed_match_game_players(game)
    end
    update!(status: :map_banning)
  end

  def advance_to_race_picking
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
    league.maps.where.not(id: used_map_ids)
  end

  def available_maps_for_banning
    # Exclude the week's starting map and already banned maps
    week_map = league.map_for_match(self)
    banned_map_ids = map_bans.pluck(:map_id)
    base_query = league.maps.where.not(id: banned_map_ids)
    week_map ? base_query.where.not(id: week_map.id) : base_query
  end

  def available_maps_for_picking
    # Available: league maps minus bans, minus already used maps, minus week's starting map
    week_map = league.map_for_match(self)
    used_map_ids = games.where.not(map_id: nil).pluck(:map_id)
    banned_map_ids = map_bans.where(game_number: current_game&.game_number).pluck(:map_id)
    
    base_query = league.maps.where.not(id: used_map_ids + banned_map_ids)
    week_map ? base_query.where.not(id: week_map.id) : base_query
  end

  def both_maps_banned?
    current_game_number = current_game&.game_number || 1
    match_players.count == map_bans.where(game_number: current_game_number).count
  end
  
  def needs_race_selection?
    # Game 1 needs race selection after map is picked (map_banning flow)
    # Game 2+: races picked before map, so no race selection needed after map
    current_game&.game_number == 1
  end
  
  def report_winner(winner_player, _winner_id = nil)
    return unless current_game
    
    current_game.update!(winner: winner_player, status: :completed)
    
    # Check if match is over (2 wins)
    if player1_score == 2 || player2_score == 2
      update!(status: :completed)
    else
      # Create next game and advance to races_picking (loser will pick map after race reveal)
      next_game_number = games.maximum(:game_number).to_i + 1
      next_game = games.create!(game_number: next_game_number, status: :pending)
      seed_match_game_players(next_game)
      update!(status: :races_picking)
    end
  end
  
  def both_players_ready?
    match_players.all?(&:ready)
  end
  
  def both_races_selected?
    return false unless current_game
    slots = current_game.match_game_players
    slots.count == match_players.count && slots.where(race_id: nil).none?
  end
  
  def my_match_player(player)
    match_players.find_by(player: player)
  end
  
  def opponent_of(player)
    players.where.not(id: player.id).first
  end
  
  def available_races_for(player)
    return [] unless game

    # Any race this player has ever *won* with in this match is locked out for
    # the rest of the set. Losing with a race does not lock it out — only
    # winning does. So a player who wins game 1 with Orc, loses game 2 as
    # Human, still cannot pick Orc again for game 3.
    won_race_ids = games.where(status: :completed, winner: player)
                        .joins(match_game_players: :match_player)
                        .where(match_players: { player_id: player.id })
                        .pluck("match_game_players.race_id")
                        .compact

    scope = game.races
    scope = scope.where.not(id: won_race_ids) if won_race_ids.any?
    scope.to_a
  end

  # Backwards-compatible alias used in places where we don't yet know the
  # player context (returns the union of restrictions, i.e. only excludes a
  # race if *every* player would be barred from picking it — which is never).
  def available_races
    return [] unless game
    game.races.to_a
  end

  private

  # Create one MatchGamePlayer slot per match_player for the given game so race
  # picks for that game have a place to live.
  def seed_match_game_players(game)
    match_players.find_each do |mp|
      game.match_game_players.find_or_create_by!(match_player: mp)
    end
  end
end

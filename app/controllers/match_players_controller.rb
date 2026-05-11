class MatchPlayersController < ApplicationController
  before_action :set_match_player, only: [:ready, :pick_race, :ban_map]
  before_action :require_authentication
  
  def ready
    @match_player.update!(ready: true)
    
    if @match_player.match.both_players_ready?
      # First game: start with map banning
      @match_player.match.advance_to_map_banning
    else
      @match_player.match.update!(status: :lobby) if @match_player.match.pending?
    end
    
    redirect_to @match_player.match
  end

  def ban_map
    map = Map.find(params[:map_id])
    game_number = @match_player.match.current_game&.game_number || 1
    
    # Only allow ban if not already banned by this player for this game
    if @match_player.banned_map_id.nil?
      @match_player.update!(banned_map_id: map.id)
      # Create the MapBan record
      MapBan.find_or_create_by!(
        match: @match_player.match,
        player: @match_player.player,
        map: map,
        game_number: game_number
      )
    end

    if @match_player.match.both_maps_banned?
      # Both players have banned, loser picks the map
      @match_player.match.update!(status: :map_picking)
    end

    redirect_to @match_player.match
  end
  
  def pick_race
    @match_player.update!(race_id: params[:race_id])
    
    if @match_player.match.both_races_selected?
      @match_player.match.advance_to_race_reveal
      @match_player.match.advance_to_map_selection
    end
    
    redirect_to @match_player.match
  end
  
  private
  
  def set_match_player
    @match_player = MatchPlayer.find(params[:id])
  end
end

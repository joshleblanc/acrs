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
    match = @match_player.match
    game = match.current_game
    game_number = game&.game_number || 1

    slot = game&.player_slot(@match_player.player)
    if slot && slot.banned_map_id.nil?
      slot.update!(banned_map_id: map.id)
      MapBan.find_or_create_by!(
        match: match,
        player: @match_player.player,
        map: map,
        game_number: game_number
      )
    end

    if match.both_maps_banned?
      match.update!(status: :in_progress)
    end

    redirect_to match
  end

  def pick_race
    match = @match_player.match
    slot = match.current_game&.player_slot(@match_player.player)
    slot&.update!(race_id: params[:race_id])

    if match.both_races_selected?
      match.advance_to_race_reveal
      match.advance_to_map_selection
    end

    redirect_to match
  end
  
  private
  
  def set_match_player
    @match_player = MatchPlayer.find(params[:id])
  end
end

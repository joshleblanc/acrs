class MatchPlayersController < ApplicationController
  before_action :set_match_player, only: [:ready, :pick_race]
  before_action :require_authentication
  
  def ready
    @match_player.update!(ready: true)
    
    if @match_player.match.both_players_ready?
      @match_player.match.advance_to_race_picking
    else
      @match_player.match.update!(status: :lobby) if @match_player.match.pending?
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

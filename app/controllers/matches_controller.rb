class MatchesController < ApplicationController
  before_action :set_match, only: [:show, :pick_map, :report_result, :confirm_result]
  before_action :require_authentication
  
  def index
    @players = Current.user.players.includes(:matches => [:league, :match_players => [:player]])
    @all_matches = @players.flat_map(&:matches).uniq.sort_by { |m| m.scheduled_at || Time.now }
    @upcoming = @all_matches.select { |m| m.pending? || m.lobby? || m.races_picking? || m.races_revealed? || m.map_picking? || m.in_progress? }
    @completed = @all_matches.select(&:completed?)
  end
  
  def show
    @my_player = @match.players.find_by(user: Current.user)
    @opponent = @match.opponent_of(@my_player)
    @my_match_player = @match.my_match_player(@my_player)
  end
  
  def pick_map
    @match.current_game&.update!(map_id: params[:map_id])
    # After map is picked:
    # - Game 1: go directly to in_progress
    # - Game 2+: loser picked map, now race selection
    if @match.needs_race_selection?
      @match.advance_to_in_progress
    else
      @match.update!(status: :races_picking)
    end
    redirect_to @match
  end
  
  def report_result
    @my_player = @match.players.find_by(user: Current.user)
    @opponent = @match.opponent_of(@my_player)
    
    # Both players need to report, or auto-confirm if opponent already reported same result
    my_report = params[:winner_id].to_i == @my_player.id
    @match.report_winner(my_report ? @my_player : @opponent)
    
    redirect_to @match
  end
  
  def confirm_result
    @my_player = @match.players.find_by(user: Current.user)
    winner_id = params[:winner_id].to_i
    winner = @match.players.find(winner_id)
    @match.report_winner(winner)
    redirect_to @match
  end
  
  private
  
  def set_match
    @match = Match.find(params[:id])
  end
end

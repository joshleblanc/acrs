class DashboardController < ApplicationController
  before_action :require_authentication
  
  def index
    @player = Current.user.players.includes(:league).first
    
    if @player
      @league = @player.league
      @upcoming_matches = @player.matches.where(status: [:not_started, :ongoing]).order(:scheduled_at).limit(5)
      @recent_results = @player.matches.where(status: :completed).order(updated_at: :desc).limit(5)
    end
  end
end

class LeaguesController < ApplicationController
  before_action :set_league, only: [:show, :invite, :signup]
  before_action :require_authentication, except: [:index, :show, :invite]
  
  def index
    @leagues = League.where(status: [:accepting_signups, :active]).order(created_at: :desc)
  end
  
  def show
    @invite = @league.active_invite if params[:token].present?
    @player = @league.player_for(Current.user) if authenticated?
  end
  
  def invite
    @invite = Invite.active.available.find_by(token: params[:token])
    
    if @invite.nil?
      redirect_to @invite&.league || leagues_path, alert: "Invalid or expired invite link."
      return
    end
    
    @league = @invite.league
    @player = @league.player_for(Current.user) if authenticated?
    
    render :show
  end
  
  def signup
    if @league.user_signed_up?(Current.user)
      redirect_to @league, notice: "You're already signed up for this league."
      return
    end
    
    unless @league.accepting_signups?
      redirect_to @league, alert: "This league is not accepting signups."
      return
    end
    
    @player = @league.players.create!(
      user: Current.user,
      name: params[:display_name].presence || Current.user.username
    )
    
    redirect_to @league, notice: "Successfully signed up for #{@league.name}!"
  end
  
  private
  
  def set_league
    @league = League.find(params[:id])
  rescue ActiveRecord::RecordNotFound
    redirect_to leagues_path, alert: "League not found."
  end
end

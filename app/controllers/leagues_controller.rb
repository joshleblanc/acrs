class LeaguesController < ApplicationController
  before_action :set_league, only: [:show, :invite, :signup]
  before_action :require_authentication, except: [:index, :show, :invite]
  
  def index
    @leagues = League.where(status: [:accepting_signups, :active]).order(created_at: :desc)
  end
  
  def show
    @invite = @league.active_invite if params[:token].present?
    @player = @league.player_for(Current.user) if authenticated?

    if @league.active?
      upcoming = @league.matches
                        .where.not(status: :completed)
                        .includes(:group, match_players: :player)
                        .order(:round_number, :id)

      # Hash of group => { round_number => [matches] }, ordered by tier.
      @upcoming_by_group = @league.groups.ordered.each_with_object({}) do |group, h|
        group_matches = upcoming.select { |m| m.group_id == group.id }
        next if group_matches.empty?
        h[group] = group_matches.group_by(&:round_number).sort.to_h
      end
    end
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

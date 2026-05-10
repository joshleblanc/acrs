module Madmin
  class LeaguesController < Madmin::ResourceController
    def start_season
      league = League.find(params[:id])
      if league.accepting_signups?
        LeagueActivationService.new(league).activate!
        redirect_to madmin_league_path(league), notice: "Season started! Groups and matches created."
      else
        redirect_to madmin_league_path(league), alert: "League must be accepting signups to start the season."
      end
    end 
  end
end

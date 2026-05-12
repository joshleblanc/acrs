module Madmin
  class LeaguesController < Madmin::ResourceController
    def start_season
      league = League.find(params[:id])

      unless league.accepting_signups?
        redirect_to main_app.madmin_league_path(league),
                    alert: "League must be accepting signups to start the season."
        return
      end

      if LeagueActivationService.new(league).activate!
        redirect_to main_app.madmin_league_path(league),
                    notice: "Season started! Groups and matches created."
      else
        redirect_to main_app.madmin_league_path(league),
                    alert: "Could not start season: #{league.errors.full_messages.to_sentence.presence || 'unknown error'}."
      end
    end
  end
end

class PromotionService
  def initialize(league)
    @league = league
  end
  
  def promote_and_relegate!
    @league.groups.ordered.each do |group|
      next if group.players.empty?
      
      ranked_players = rank_players_in_group(group)
      
      # Get adjacent groups
      higher_group = @league.groups.find_by(tier: group.tier - 1)
      lower_group = @league.groups.find_by(tier: group.tier + 1)
      
      # Promote top player (if not in highest tier and higher group exists)
      if ranked_players.any? && higher_group
        top_player = ranked_players.first
        promote_player(top_player, higher_group)
      end
      
      # Relegate bottom player (if not in lowest tier and lower group exists)
      if ranked_players.any? && lower_group
        bottom_player = ranked_players.last
        relegate_player(bottom_player, lower_group)
      end
    end
  end
  
  private
  
  def rank_players_in_group(group)
    # Rank by wins in completed matches
    players_with_scores = group.players.map do |player|
      wins = player.matches
                  .where(status: :completed)
                  .where(id: Match.where.not(id: nil))
                  .where(matches: { id: player.matches.pluck(:id) })
                  .where(matches: Match.joins(:games).where(games: { winner_id: player.id }))
                  .count
      
      { player: player, wins: wins }
    end
    
    players_with_scores.sort_by { |ps| -ps[:wins] }.map { |ps| ps[:player] }
  end
  
  def promote_player(player, target_group)
    # Remove from current group
    player.group_assignments.destroy_all
    
    # Add to new group
    player.group_assignments.create!(group: target_group)
  end
  
  alias_method :relegate_player, :promote_player
end

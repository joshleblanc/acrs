class LeagueActivationService
  MIN_PLAYERS_PER_GROUP = 4
  MAX_PLAYERS_PER_GROUP = 4
  DEFAULT_PLAYERS_PER_GROUP = 4
  
  TIER_NAMES = %w[S A B C D E F G H].freeze
  
  def initialize(league)
    @league = league
  end
  
  def activate!
    return false unless @league.accepting_signups?

    ActiveRecord::Base.transaction do
      reset_existing!
      create_groups!
      assign_players_to_groups!
      schedule_matches!
      @league.update!(status: :active)
    end

    true
  rescue ActiveRecord::RecordInvalid, ArgumentError => e
    @league.errors.add(:base, e.message)
    false
  end

  private

  # Wipe any prior activation artifacts so re-running activate! produces a
  # clean slate (fresh groups, fresh assignments, fresh schedule).
  def reset_existing!
    @league.matches.destroy_all
    @league.groups.destroy_all
  end

  def create_groups!
    group_count = calculate_group_count
    group_count.times do |i|
      tier = i
      name = TIER_NAMES[i] || "Group #{i + 1}"
      
      @league.groups.create!(
        name: name,
        tier: tier,
        min_players: MIN_PLAYERS_PER_GROUP,
        max_players: MAX_PLAYERS_PER_GROUP
      )
    end
  end
  
  def calculate_group_count
    player_count = @league.players.count
    
    if player_count < MIN_PLAYERS_PER_GROUP
      raise ArgumentError, "Not enough players to form a group (need at least #{MIN_PLAYERS_PER_GROUP})"
    end
    
    ideal_groups = (player_count.to_f / DEFAULT_PLAYERS_PER_GROUP).ceil
    
    [ideal_groups, TIER_NAMES.size].min
  end
  
  def assign_players_to_groups!
    players = @league.players.order(Arel.sql("RANDOM()")).to_a
    
    # Sort groups by tier (lowest number = highest skill = first)
    sorted_groups = @league.groups.ordered.to_a
    
    player_index = 0
    group_index = 0
    
    while player_index < players.size
      group = sorted_groups[group_index]
      next_group_index = (group_index + 1) % sorted_groups.size
      
      # If current group is full, move to next
      if group.players.count >= group.max_players
        group_index = next_group_index
        next if group_index == 0 # Avoid infinite loop
        next
      end
      
      player = players[player_index]
      player.group_assignments.create!(group: group)
      player_index += 1
      
      # Move to next group if current is full
      group_index = next_group_index if group.players.count >= group.max_players
    end
  end
  
  def schedule_matches!
    @league.groups.ordered.each do |group|
      next if group.players.count < 2
      
      scheduler = RoundRobinScheduler.new(group)
      scheduler.schedule!
    end
  end
end

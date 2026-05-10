class RoundRobinScheduler
  def initialize(group)
    @group = group
    @players = group.players.order(:id).to_a
  end
  
  def schedule!
    return [] if @players.size < 2
    
    rounds = generate_rounds
    matches = []
    
    rounds.each_with_index do |round, round_index|
      round.each_with_index do |pair, _match_index|
        player1, player2 = pair
        matches << create_match(player1, player2, round_index + 1)
      end
    end
    
    matches
  end
  
  private
  
  def generate_rounds
    n = @players.size
    rounds = []
    
    # Circle method for round-robin
    # If odd number of players, add a bye (nil)
    players = n.odd? ? @players + [nil] : @players.dup
    
    # Rotate and pair
    (n - 1).times do |i|
      round = []
      (players.size / 2).times do |j|
        player1 = players[j]
        player2 = players[-(j + 1)]
        
        # Skip if both are nil (bye week)
        next if player1.nil? && player2.nil?
        next if player1.nil? || player2.nil?
        
        round << [player1, player2]
      end
      rounds << round
      
      # Rotate all players except the first
      players = [players.first] + players.last(1) + players[1...-1]
    end
    
    rounds
  end
  
  def create_match(player1, player2, round_number)
    @group.league.matches.create!(
      match_players_attributes: [
        { player: player1 },
        { player: player2 }
      ]
    )
  end
end

require "test_helper"

class MatchTest < ActiveSupport::TestCase
  self.use_transactional_tests = true
  
  setup do
    # Create game with races and maps
    @game = Game.create!(name: "Warcraft 3_#{SecureRandom.hex(4)}")
    @race1 = @game.races.create!(name: "Human")
    @race2 = @game.races.create!(name: "Orc")
    @map1 = @game.maps.create!(name: "Map1")
    @map2 = @game.maps.create!(name: "Map2")
    @map3 = @game.maps.create!(name: "Map3")
    
    # Create league
    @league = @game.leagues.create!(name: "Test League", status: :accepting_signups)
    
    # Create users with unique identifiers
    unique = SecureRandom.hex(4)
    @user1 = User.create!(
      username: "player1_#{unique}", 
      email_address: "player1_#{unique}@test.com", 
      password: "password"
    )
    @user2 = User.create!(
      username: "player2_#{unique}", 
      email_address: "player2_#{unique}@test.com", 
      password: "password"
    )
    @player1 = @league.players.create!(name: "Player 1", user: @user1)
    @player2 = @league.players.create!(name: "Player 2", user: @user2)
    
    # Create match
    @match = @league.matches.create!
    @match.match_players.create!(player: @player1)
    @match.match_players.create!(player: @player2)
  end
  
  test "match flow: pending to ready to races_picking" do
    assert_equal "pending", @match.status
    
    # Both players ready
    @match.match_players.update_all(ready: true)
    @match.advance_to_race_picking
    
    assert_equal "races_picking", @match.status
    assert_equal 1, @match.games.count
  end
  
  test "match flow: race selection to map selection" do
    @match.match_players.update_all(ready: true)
    @match.advance_to_race_picking
    
    # Pick races
    @match.match_players.first.update!(race: @race1)
    @match.match_players.last.update!(race: @race2)
    
    @match.advance_to_race_reveal
    @match.advance_to_map_selection
    
    assert_equal "map_picking", @match.status
  end
  
  test "match flow: map selection to in_progress" do
    setup_to_map_selection
    
    @match.current_game.update!(map_id: @map1.id)
    @match.advance_to_in_progress
    
    assert_equal "in_progress", @match.status
  end
  
  test "match flow: game 1 report creates game 2" do
    setup_to_in_progress
    
    # Report game 1 winner (player 1)
    @match.report_winner(@player1)
    
    assert_equal 2, @match.games.count
    assert_equal "map_picking", @match.status
    assert_equal 1, @match.games.first.game_number
    assert_equal @player1, @match.games.first.winner
  end
  
  test "loser_of_last_game returns correct player after game 1" do
    setup_to_in_progress
    
    @match.report_winner(@player1)
    
    assert_equal @player2, @match.loser_of_last_game
    assert_equal @player2, @match.map_picker
  end
  
  test "available_maps excludes already played maps" do
    setup_to_in_progress
    
    @match.report_winner(@player1)
    
    available = @match.available_maps.to_a
    assert_equal 2, available.count
    refute_includes available, @map1
    assert_includes available, @map2
    assert_includes available, @map3
  end
  
  test "game 2: loser picks map" do
    setup_to_in_progress
    
    @match.report_winner(@player1)
    
    # Player 2 (loser) should pick the map for game 2
    assert_equal @player2, @match.map_picker
    
    # Pick map for game 2
    @match.current_game.update!(map_id: @map2.id)
    
    # After map picked, should advance to race selection
    if @match.needs_race_selection?
      @match.advance_to_in_progress
    else
      @match.update!(status: :races_picking)
    end
    
    assert_equal "races_picking", @match.status
  end
  
  test "match completes after 2 wins" do
    setup_to_in_progress
    
    # Player 1 wins game 1
    @match.report_winner(@player1)
    
    # Player 2 picks map for game 2
    @match.current_game.update!(map_id: @map2.id)
    @match.update!(status: :races_picking)
    
    # Pick races for game 2
    @match.match_players.first.update!(race: @race2)
    @match.match_players.last.update!(race: @race1)
    @match.advance_to_race_reveal
    @match.advance_to_map_selection
    @match.current_game.update!(map_id: @map3.id)
    @match.advance_to_in_progress
    
    # Player 1 wins game 2 (and match)
    @match.report_winner(@player1)
    
    assert_equal "completed", @match.status
    assert_equal @player1, @match.winner
  end
  
  private
  
  def setup_to_map_selection
    @match.match_players.update_all(ready: true)
    @match.advance_to_race_picking
    @match.match_players.first.update!(race: @race1)
    @match.match_players.last.update!(race: @race2)
    @match.advance_to_race_reveal
    @match.advance_to_map_selection
  end
  
  def setup_to_in_progress
    setup_to_map_selection
    @match.current_game.update!(map_id: @map1.id)
    @match.advance_to_in_progress
  end
end

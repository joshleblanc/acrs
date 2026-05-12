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
    
    # Create league with maps
    @league = @game.leagues.create!(name: "Test League", status: :accepting_signups)
    @league.league_maps.create!(map: @map1, order: 0)
    @league.league_maps.create!(map: @map2, order: 1)
    @league.league_maps.create!(map: @map3, order: 2)
    
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
  
  test "match flow: pending to ready to map_banning" do
    assert_equal "pending", @match.status
    
    # Both players ready
    @match.match_players.update_all(ready: true)
    @match.advance_to_map_banning
    
    assert_equal "map_banning", @match.status
    assert_equal 1, @match.games.count
  end
  
  test "match flow: map banning to map picking" do
    @match.match_players.update_all(ready: true)
    @match.advance_to_map_banning

    # Both players ban maps
    game = @match.current_game
    game.player_slot(@player1).update!(banned_map_id: @map1.id)
    game.player_slot(@player2).update!(banned_map_id: @map2.id)
    MapBan.create!(match: @match, player: @player1, map: @map1, game_number: 1)
    MapBan.create!(match: @match, player: @player2, map: @map2, game_number: 1)

    @match.update!(status: :map_picking)

    assert_equal "map_picking", @match.status
  end
  
  test "available_maps_for_banning excludes week's starting map" do
    @match.match_players.update_all(ready: true)
    @match.advance_to_map_banning
    
    # Week's map is determined by match position in league
    week_map = @league.map_for_match(@match)
    
    available = @match.available_maps_for_banning.to_a
    refute_includes available, week_map
  end
  
  test "match flow: race selection to map selection" do
    @match.match_players.update_all(ready: true)
    @match.advance_to_map_banning

    # Pick races for the current game
    game = @match.current_game
    game.player_slot(@player1).update!(race: @race1)
    game.player_slot(@player2).update!(race: @race2)

    @match.advance_to_race_reveal
    @match.advance_to_map_selection

    assert_equal "map_picking", @match.status
  end
  
  test "match flow: map selection to in_progress" do
    setup_to_in_progress
    
    @match.current_game.update!(map_id: @map1.id)
    @match.advance_to_in_progress
    
    assert_equal "in_progress", @match.status
  end
  
  test "match flow: game 1 report creates game 2" do
    setup_to_in_progress
    
    # Report game 1 winner (player 1)
    @match.report_winner(@player1)
    
    assert_equal 2, @match.games.count
    assert_equal "races_picking", @match.status
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
    refute_includes available, @map3
    assert_includes available, @map1
    assert_includes available, @map2
  end
  
  test "game 2: loser picks map" do
    setup_to_in_progress
    
    @match.report_winner(@player1)
    
    # Player 2 (loser) should pick the map for game 2
    assert_equal @player2, @match.map_picker
    
    # Pick map for game 2
    @match.current_game.update!(map_id: @map2.id)
    
    # After map picked, for game 2 we go directly to in_progress (races were picked)
    if @match.needs_race_selection?
      @match.advance_to_race_picking
    else
      @match.advance_to_in_progress
    end
    
    assert_equal "in_progress", @match.status
  end
  
  test "match completes after 2 wins" do
    setup_to_in_progress

    # Player 1 wins game 1
    @match.report_winner(@player1)

    # Game 2: pick races first (different races than game 1 are fine)
    game2 = @match.current_game
    game2.player_slot(@player1).update!(race: @race2)
    game2.player_slot(@player2).update!(race: @race1)
    @match.advance_to_race_reveal
    @match.advance_to_map_selection

    # Loser picks map for game 2
    @match.current_game.update!(map_id: @map2.id)
    @match.advance_to_in_progress

    # Player 1 wins game 2 (and match)
    @match.report_winner(@player1)

    assert_equal "completed", @match.status
    assert_equal @player1, @match.winner
  end

  test "per-game race history is preserved across games" do
    setup_to_in_progress

    # Game 1 races recorded by setup_to_in_progress
    game1 = @match.games.order(:game_number).first
    assert_equal @race1, game1.race_for(@player1)
    assert_equal @race2, game1.race_for(@player2)

    # Player 1 wins game 1; game 2 is created and races picked.
    @match.report_winner(@player1)
    game2 = @match.current_game
    # Loser of game 1 (winner restriction): @player1 cannot repeat @race1.
    refute_includes @match.available_races, @race1

    game2.player_slot(@player1).update!(race: @race2)
    game2.player_slot(@player2).update!(race: @race1)

    # Game 1's picks are still queryable, independent of game 2's picks.
    assert_equal @race1, game1.reload.race_for(@player1)
    assert_equal @race2, game1.race_for(@player2)
    assert_equal @race2, game2.race_for(@player1)
    assert_equal @race1, game2.race_for(@player2)
  end
  
  private
  
  def setup_to_map_selection
    @match.match_players.update_all(ready: true)
    @match.advance_to_map_banning

    # Both ban maps
    game = @match.current_game
    game.player_slot(@player1).update!(banned_map_id: @map1.id)
    game.player_slot(@player2).update!(banned_map_id: @map2.id)
    MapBan.create!(match: @match, player: @player1, map: @map1, game_number: 1)
    MapBan.create!(match: @match, player: @player2, map: @map2, game_number: 1)

    @match.update!(status: :map_picking)

    # Loser picks map
    @match.current_game.update!(map_id: @map3.id)
    @match.advance_to_race_picking

    # Pick races for game 1
    game.player_slot(@player1).update!(race: @race1)
    game.player_slot(@player2).update!(race: @race2)
    @match.advance_to_race_reveal
    @match.advance_to_map_selection
  end
  
  def setup_to_in_progress
    setup_to_map_selection
    @match.current_game.update!(map_id: @map3.id) unless @match.current_game.map_id
    @match.advance_to_in_progress
  end
end

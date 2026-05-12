class CreateMatchGamePlayers < ActiveRecord::Migration[8.1]
  def up
    create_table :match_game_players do |t|
      t.references :match_game,   null: false, foreign_key: true
      t.references :match_player, null: false, foreign_key: true
      t.references :race,         null: true,  foreign_key: true
      t.references :banned_map,   null: true,  foreign_key: { to_table: :maps }

      t.timestamps
    end

    add_index :match_game_players,
              [:match_game_id, :match_player_id],
              unique: true,
              name: "index_match_game_players_on_game_and_player"

    # Backfill: for every existing MatchGame, create one MatchGamePlayer row per
    # MatchPlayer in the parent Match. Race data is only known for in-flight
    # games (the live match_player.race_id reflects the *current* game), so we
    # copy it onto the latest non-completed game. Historical race picks for
    # already-completed games were never persisted and remain null.
    say_with_time "Backfilling match_game_players" do
      execute <<~SQL
        INSERT INTO match_game_players (match_game_id, match_player_id, race_id, banned_map_id, created_at, updated_at)
        SELECT mg.id, mp.id, NULL, NULL, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP
        FROM match_games mg
        JOIN match_players mp ON mp.match_id = mg.match_id
      SQL

      # Copy live race_id / banned_map_id onto the most recent non-completed
      # game for each match_player (status != 3 = completed).
      execute <<~SQL
        UPDATE match_game_players
        SET race_id = (
              SELECT mp.race_id FROM match_players mp WHERE mp.id = match_game_players.match_player_id
            ),
            banned_map_id = (
              SELECT mp.banned_map_id FROM match_players mp WHERE mp.id = match_game_players.match_player_id
            )
        WHERE match_game_id IN (
          SELECT mg.id
          FROM match_games mg
          WHERE mg.status != 3
            AND mg.id = (
              SELECT mg2.id FROM match_games mg2
              WHERE mg2.match_id = mg.match_id AND mg2.status != 3
              ORDER BY mg2.game_number DESC
              LIMIT 1
            )
        )
      SQL
    end

    # Drop the now-redundant per-match columns. Race picks and per-game ban
    # state live on match_game_players.
    remove_foreign_key :match_players, column: :race_id if foreign_key_exists?(:match_players, column: :race_id)
    remove_foreign_key :match_players, column: :banned_map_id if foreign_key_exists?(:match_players, column: :banned_map_id)
    remove_index :match_players, :race_id if index_exists?(:match_players, :race_id)
    remove_column :match_players, :race_id
    remove_column :match_players, :banned_map_id
    remove_column :match_players, :race if column_exists?(:match_players, :race)
  end

  def down
    add_column :match_players, :race_id, :integer
    add_column :match_players, :banned_map_id, :integer
    add_column :match_players, :race, :string
    add_index :match_players, :race_id
    add_foreign_key :match_players, :races
    add_foreign_key :match_players, :maps, column: :banned_map_id

    drop_table :match_game_players
  end
end

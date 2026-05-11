class AddBannedMapToMatchPlayers < ActiveRecord::Migration[8.0]
  def change
    add_column :match_players, :banned_map_id, :integer
    add_foreign_key :match_players, :maps, column: :banned_map_id
  end
end

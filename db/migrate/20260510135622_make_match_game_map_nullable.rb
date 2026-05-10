class MakeMatchGameMapNullable < ActiveRecord::Migration[8.1]
  def change
    change_column_null :match_games, :map_id, true
    change_column_null :match_games, :winner_id, true
  end
end

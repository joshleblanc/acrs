class FixMatchGameWinnerForeignKey < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key :match_games, :winners
    add_foreign_key :match_games, :players, column: :winner_id
  end
end

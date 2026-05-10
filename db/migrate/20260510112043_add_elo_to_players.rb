class AddEloToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :players, :elo, :float
  end
end

class AddRaceAndReadyToMatchPlayers < ActiveRecord::Migration[8.1]
  def change
    add_column :match_players, :race, :string
    add_column :match_players, :ready, :boolean
  end
end

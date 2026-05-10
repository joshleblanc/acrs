class CreateMatchGames < ActiveRecord::Migration[8.1]
  def change
    create_table :match_games do |t|
      t.references :match, null: false, foreign_key: true
      t.integer :game_number
      t.references :map, null: false, foreign_key: true
      t.references :winner, null: false, foreign_key: true
      t.integer :status

      t.timestamps
    end
  end
end

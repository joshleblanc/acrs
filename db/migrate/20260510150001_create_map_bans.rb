class CreateMapBans < ActiveRecord::Migration[8.0]
  def change
    create_table :map_bans do |t|
      t.references :match, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true
      t.references :map, null: false, foreign_key: true
      t.integer :game_number, null: false

      t.timestamps
    end
  end
end

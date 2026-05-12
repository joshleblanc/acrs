class CreateLeagueMaps < ActiveRecord::Migration[8.0]
  def change
    create_table :league_maps do |t|
      t.references :league, null: false, foreign_key: true
      t.references :map, null: false, foreign_key: true
      t.integer :order, default: 0

      t.timestamps
    end
  end
end

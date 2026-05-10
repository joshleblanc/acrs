class CreateGroups < ActiveRecord::Migration[8.1]
  def change
    create_table :groups do |t|
      t.references :league, null: false, foreign_key: true
      t.string :name
      t.integer :tier
      t.integer :min_players
      t.integer :max_players

      t.timestamps
    end
  end
end

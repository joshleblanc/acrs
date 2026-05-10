class CreateLeagues < ActiveRecord::Migration[8.1]
  def change
    create_table :leagues do |t|
      t.string :name
      t.belongs_to :game, null: false, foreign_key: true

      t.timestamps
    end
  end
end

class CreateMaps < ActiveRecord::Migration[8.1]
  def change
    create_table :maps do |t|
      t.string :name
      t.belongs_to :game, null: false, foreign_key: true

      t.timestamps
    end
  end
end

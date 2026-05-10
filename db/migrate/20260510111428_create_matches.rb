class CreateMatches < ActiveRecord::Migration[8.1]
  def change
    create_table :matches do |t|
      t.belongs_to :league, null: false, foreign_key: true
      t.integer :status, default: 0

      t.timestamps
    end
  end
end

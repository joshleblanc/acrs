class CreateInvites < ActiveRecord::Migration[8.1]
  def change
    create_table :invites do |t|
      t.references :league, null: false, foreign_key: true
      t.string :token
      t.datetime :expires_at
      t.integer :max_signups

      t.timestamps
    end
    add_index :invites, :token
  end
end

class CreateGroupAssignments < ActiveRecord::Migration[8.1]
  def change
    create_table :group_assignments do |t|
      t.references :group, null: false, foreign_key: true
      t.references :player, null: false, foreign_key: true

      t.timestamps
    end
  end
end

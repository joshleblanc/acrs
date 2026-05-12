class AddRoundAndGroupToMatches < ActiveRecord::Migration[8.1]
  def change
    add_reference :matches, :group, null: true, foreign_key: true
    add_column   :matches, :round_number, :integer
    add_index    :matches, [:league_id, :round_number]
  end
end

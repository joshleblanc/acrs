class AddScheduledAtToMatches < ActiveRecord::Migration[8.1]
  def change
    add_column :matches, :scheduled_at, :datetime
  end
end

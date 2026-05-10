class AddUserToPlayers < ActiveRecord::Migration[8.1]
  def change
    add_reference :players, :user, foreign_key: true
  end
end

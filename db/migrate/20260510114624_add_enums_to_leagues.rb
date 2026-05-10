class AddEnumsToLeagues < ActiveRecord::Migration[8.1]
  def change
    add_column :leagues, :status, :integer
    add_column :leagues, :match_day, :integer
  end
end

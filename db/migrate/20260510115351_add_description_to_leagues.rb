class AddDescriptionToLeagues < ActiveRecord::Migration[8.1]
  def change
    add_column :leagues, :description, :string
  end
end

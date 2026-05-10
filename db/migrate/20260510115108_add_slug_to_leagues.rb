class AddSlugToLeagues < ActiveRecord::Migration[8.1]
  def change
    add_column :leagues, :slug, :string
  end
end

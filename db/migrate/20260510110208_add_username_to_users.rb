class AddUsernameToUsers < ActiveRecord::Migration[8.1]
  def change
    add_column :users, :username, :string
    add_index :users, :username, unique: true
    
    # Set username from email for existing users
    User.update_all("username = SUBSTR(email_address, 1, INSTR(email_address, '@') - 1)")
    
    change_column_null :users, :username, false
  end
end

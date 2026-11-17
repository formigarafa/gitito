# Moves users from Devise's columns to the ones has_secure_password expects.
# Password reset and remember-me no longer need columns: reset tokens are
# signed and sessions live in their own table.
class ReplaceDeviseColumnsOnUsers < ActiveRecord::Migration[8.1]
  def change
    rename_column :users, :encrypted_password, :password_digest
    change_column_default :users, :password_digest, from: "", to: nil

    remove_index :users, column: :reset_password_token, unique: true
    remove_column :users, :reset_password_token, :string
    remove_column :users, :reset_password_sent_at, :datetime
    remove_column :users, :remember_created_at, :datetime
  end
end

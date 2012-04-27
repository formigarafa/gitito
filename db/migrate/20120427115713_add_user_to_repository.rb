class AddUserToRepository < ActiveRecord::Migration
  def self.up
    add_column :repositories, :user_id, :integer
  end

  def self.down
    remove_column :repositories, :user_id
  end
end

# frozen_string_literal: true

class AddUserToRepository < ActiveRecord::Migration[4.2]
  def self.up
    add_column :repositories, :user_id, :integer
  end

  def self.down
    remove_column :repositories, :user_id
  end
end

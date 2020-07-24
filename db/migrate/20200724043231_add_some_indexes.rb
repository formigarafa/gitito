# frozen_string_literal: true

class AddSomeIndexes < ActiveRecord::Migration
  def change
    add_index :collaborators, %i[repository_id user_id], unique: true
    add_index :repositories, %i[name user_id], unique: true
    add_index :user_credentials, :key, unique: true
  end
end

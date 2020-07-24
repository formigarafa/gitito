# frozen_string_literal: true

class CreateCollaborators < ActiveRecord::Migration
  def self.up
    create_table :collaborators do |t|
      t.integer :user_id
      t.integer :repository_id

      t.timestamps
    end
  end

  def self.down
    drop_table :collaborators
  end
end

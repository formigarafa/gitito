class CreateUserCredentials < ActiveRecord::Migration
  def self.up
    create_table :user_credentials do |t|
      t.string :title
      t.text :key
      t.integer :user_id

      t.timestamps
    end
  end

  def self.down
    drop_table :user_credentials
  end
end

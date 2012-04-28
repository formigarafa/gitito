class UserCredential < ActiveRecord::Base
	belongs_to :user
	validates :key, :presence => true
	validates :user, :presence => true
end

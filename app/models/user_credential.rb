class UserCredential < ActiveRecord::Base
	belongs_to :user
	validates :key, :presence => true, :uniqueness => true
	validates :user, :presence => true
end

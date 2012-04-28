class UserCredential < ActiveRecord::Base
	belongs_to :user
	validates :key, :presence => true, :uniqueness => true
	validates :user, :presence => true

	class << self
		def generate_authorized_keys_file
		end
	end
end

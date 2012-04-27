class Repository < ActiveRecord::Base
	belongs_to :user

	attr_readonly :name

	validates :name, :presence => true, :format => { :with => /^[a-zA-Z0-9\-_.]*$/ }
	validates :user, :presence => true

	def self.repos_root
		"#{Rails.root}/db/users_repositories"
	end
end

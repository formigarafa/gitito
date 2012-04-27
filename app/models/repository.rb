class Repository < ActiveRecord::Base
	attr_readonly :name

	validates :name, :presence => true, :format => { :with => /^[a-zA-Z0-9\-_.]*$/ }

	def self.repos_root
		"#{Rails.root}/db/users_repositories"
	end
end

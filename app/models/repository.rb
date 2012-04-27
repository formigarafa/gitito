class Repository < ActiveRecord::Base
	belongs_to :user

	attr_readonly :name

	validates :name, :presence => true, :format => { :with => /^[a-zA-Z0-9\-_.]*$/ }
	validates :user, :presence => true

	def self.repos_root
		"#{Rails.root}/db/users_repositories"
	end

	def server_path
		"#{self.class.repos_root}/#{user.username}/#{name}.git"
	end

	def ssh_user
		Rails.configuration.gitito[:ssh_user]
	end

	def ssh_host
		Rails.configuration.gitito[:ssh_host]
	end

	def url
		"#{ssh_user}@#{ssh_host}:#{user.username}/#{name}.git"
	end
end

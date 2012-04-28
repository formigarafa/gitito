class UserCredential < ActiveRecord::Base
	belongs_to :user
	validates :key, :presence => true, :uniqueness => true
	validates :user, :presence => true

	class << self
		def generate_authorized_keys_file
			destination_folder = File.dirname(authorized_keys_absolute_path)
			FileUtils.mkdir_p(destination_folder) unless File.exists? destination_folder
		end

		def authorized_keys_absolute_path
			File.expand_path Rails.configuration.gitito[:ssh_authorized_keys_file]
		end
	end
end

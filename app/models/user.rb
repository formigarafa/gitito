class User < ActiveRecord::Base
	# Include default devise modules. Others available are:
	# :token_authenticatable, :encryptable, :confirmable, :lockable, :timeoutable and :omniauthable
	devise :database_authenticatable, :registerable,
	     :recoverable, :rememberable, :trackable, :validatable

	# Setup accessible (or protected) attributes for your model
	attr_accessible :username, :email, :password, :password_confirmation, :remember_me
	validates :username, :presence => true, :format => { :with => /^[a-zA-Z0-9\-_.]*$/ }

	has_many :user_credentials
	has_many :repositories
end

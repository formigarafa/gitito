require 'spec_helper'

describe User do
	def valid_user
		User.new :username => "N4m3_W1th-V4l1d.Ch4r", :email => 'anyone@somedomain.com', :password => '1qaz2wsx'
	end

	context "validity" do
		it "validates with valid attributes" do
			valid_user.should be_valid
		end

		it "validates with matching password_confirmation" do
			user = valid_user
			user.password = 'p4ssw0rd'
			user.password_confirmation = 'p4ssw0rd'
			user.should be_valid
		end


		it "fails with no username" do
			user = valid_user
			user.username = nil
			user.should_not be_valid
		end

		it "fails with no email" do
			user = valid_user
			user.email = nil
			user.should_not be_valid
		end

		it "fails with no password" do
			user = valid_user
			user.password = nil
			user.should_not be_valid
		end

		it "fails when password does not match password_confirmation" do
			user = valid_user
			user.password = '1qaz2wsx'
			user.password_confirmation = '0okm9ijn'
			user.should_not be_valid
		end

		it "fails with complicated username (special characters)" do
			user = valid_user
			user.username = "f*cking_user"
			user.should_not be_valid
		end

		it "fails with spaces on username" do
			user = valid_user
			user.username = "some user name"
			user.should_not be_valid
		end

	end

	context "being destroyed" do
		it "destroys its credentials"
		it "destroys collaborative presence on third party repositories"
		it "destroys its repositories" # think about it...
	end

	it "has relations with collaborative repositories"
	it "generates gravatar url from user email"
end
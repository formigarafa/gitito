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
			repo = valid_user
			repo.password = 'p4ssw0rd'
			repo.password_confirmation = 'p4ssw0rd'
			repo.should be_valid
		end


		it "fails with no username" do
			repo = valid_user
			repo.username = nil
			repo.should_not be_valid
		end

		it "fails with no email" do
			repo = valid_user
			repo.email = nil
			repo.should_not be_valid
		end

		it "fails with no password" do
			repo = valid_user
			repo.password = nil
			repo.should_not be_valid
		end

		it "fails when password does not match password_confirmation" do
			repo = valid_user
			repo.password = '1qaz2wsx'
			repo.password_confirmation = '0okm9ijn'
			repo.should_not be_valid
		end

		it "fails with complicated username (special characters)" do
			repo = valid_user
			repo.username = "f*cking_user"
			repo.should_not be_valid
		end

		it "fails with spaces on username" do
			repo = valid_user
			repo.username = "some user name"
			repo.should_not be_valid
		end

	end

	
end
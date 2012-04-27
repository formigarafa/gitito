require 'spec_helper'

describe User do
	def valid_user
		User.new :username => "N4m3_W1th-V4l1d.Ch4r"
	end

	context "validity" do
		it "validates with valid attributes" do
			valid_user.should be_valid
		end

		it "fails with no username" do
			repo = valid_user
			repo.username = nil
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
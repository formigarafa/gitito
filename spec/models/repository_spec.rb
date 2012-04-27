require 'spec_helper'

describe Repository do
	def valid_repo
		Repository.new :name => "N4m3_W1th-V4l1d.Ch4r"
	end

	context "validity" do
		it "validates with valid attributes" do
			valid_repo.should be_valid
		end

		it "fails with no name" do
			repo = valid_repo
			repo.name = nil
			repo.should_not be_valid
		end

		it "fails with complicated name (special characters)" do
			repo = valid_repo
			repo.name = "f*cking_repo"
			repo.should_not be_valid
		end

		it "fails with spaces on name" do
			repo = valid_repo
			repo.name = "some repo"
			repo.should_not be_valid
		end

	end

	it "forbides repository name changes" do
		repo = valid_repo
		repo.save
		first_used_name = repo.name

		repo.name = "modified_name"
		repo.save

		repo.reload

		repo.name.should == first_used_name
	end

	specify "method dictating where I can find all repositories" do
		Repository.repos_root.should == "#{Rails.root}/db/users_repositories"
	end
end

require 'spec_helper'

describe Repository do
	def valid_repo
		Repository.new :name => "N4m3_W1th-V4l1d.Ch4r", :user => mock_model(User)
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

		it "fails with no owner" do
			repo = valid_repo
			repo.user = nil
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

	it "has method to get where I can find all repositories" do
		Repository.repos_root.should == "#{Rails.root}/db/users_repositories"
	end

	it "has method to get repository path on file server" do
		repo = Repository.new :name => "tilt", :user => stub_model( User,  :username => "formigarafa" )
		Repository.stub(:repos_root).and_return("/rOOt")
		repo.server_path.should == "/rOOt/formigarafa/tilt.git"
	end
end

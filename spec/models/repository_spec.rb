require 'spec_helper'

describe Repository do
	def valid_repo
		Repository.new :name => "N4m3_W1th-V4l1d.Ch4r", :user => mock_model(User, :username => 'juca')
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

		it "is not allowed to one user have two repositories with the same name" do
			user = mock_model(User, :username => 'juca')
			repo1 = Repository.new
			repo1.stub(:create_structure)
			repo1.name = "same_name"
			repo1.user = user
			repo1.save

			repo2 = Repository.new
			repo2.stub(:create_structure)
			repo2.user = user
			repo2.name = "same_name"

			repo2.should_not be_valid
		end

		it "is allowed for two different user have two repositories with the same name" do
			repo1 = Repository.new
			repo1.name = "same_name"
			repo1.stub(:create_structure)
			repo1.user = mock_model(User, :username => 'juca')
			repo1.save

			repo2 = Repository.new
			repo2.stub(:create_structure)
			repo2.user = mock_model(User, :username => 'drica.silva')
			repo2.name = "same_name"
			repo2.should be_valid
		end

	end

	it "forbides repository name changes" do
		repo = valid_repo
		repo.stub(:create_structure)
		repo.save
		first_used_name = repo.name

		repo.name = "modified_name"
		repo.save

		repo.reload

		repo.name.should == first_used_name
	end

	context "path" do

		it "has method to get where I can find all repositories" do
			Repository.repos_root.should == "#{Rails.root}/db/users_repositories/#{Rails.env}"
		end

		it "has method to get repository path on file server" do
			repo = Repository.new :name => "tilt", :user => stub_model( User,  :username => "formigarafa" )
			Repository.stub(:repos_root).and_return("/rOOt")
			repo.server_path.should == "/rOOt/formigarafa/tilt.git"
		end

		it "has method to get repository access url" do
			repo = Repository.new :name => "tilt", :user => stub_model( User,  :username => "formigarafa" )
			repo.stub(:ssh_user).and_return('git')
			repo.stub(:ssh_host).and_return('gitito.com')

			repo.url.should == "git@gitito.com:formigarafa/tilt.git"
		end
	end

	context "file tree" do

		it "can check if there is a folder on repository place" do
			repo = Repository.new
			repo.should_receive(:server_path).and_return("#{Rails.root}/spec/fixtures/not_repo_test")

			repo.folder_exists?.should be_true
		end

		it "can check if there is NOT a folder on repository place" do
			repo = Repository.new
			repo.should_receive(:server_path).and_return("#{Rails.root}/spec/fixtures/somewhere_else")

			repo.folder_exists?.should be_false
		end

		it "can check if there is a repo placed" do
			repo = Repository.new
			repo.should_receive(:server_path).and_return("#{Rails.root}/spec/fixtures/repo_test.git")

			repo.structure_ok?.should be_true
		end

		it "can check if there is NOT a repo placed" do
			repo = Repository.new
			repo.should_receive(:server_path).and_return("#{Rails.root}/spec/fixtures/none_repo_test.git")

			repo.structure_ok?.should be_false
		end

		it "create repository tree when doesn't exist one" do
			Dir.mktmpdir do |tmp_dir|
				repo = Repository.new
				repo.stub(:server_path).and_return(tmp_dir+"/juca/repo_tmp")
				
				repo.folder_exists?.should be_false
				repo.create_structure
				repo.folder_exists?.should be_true
			end
		end

		it "does not create repository tree when exist something there" do
			Dir.mktmpdir do |tmp_dir|
				repo = Repository.new

				repo.stub(:folder_exists?).and_return(true)
				Rugged::Repository.should_not_receive :init_at
				
				repo.create_structure
			end
		end

		it "removes structure folder" do
			Dir.mktmpdir do |tmp_dir|
				Dir.mkdir "#{tmp_dir}/1"
				Dir.mkdir "#{tmp_dir}/1/2"
				Dir.mkdir "#{tmp_dir}/1/2/3"

				repo = Repository.new
				repo.stub(:server_path).and_return("#{tmp_dir}/1")

				repo.folder_exists?.should be_true
				repo.remove_structure

				repo.folder_exists?.should be_false
			end
			
		end
	end

	context "being shared" do
		it "has many collaborators" do
			collaborators = [mock_model(Collaborator),mock_model(Collaborator)]
			collaborators.each do |collaborator|
				subject.collaborators << collaborator
			end

			subject.collaborators.should =~ collaborators
		end

		it "has no collaborators" do
			subject.collaborators.should have(0).collaborators
		end
	end

	context "method owned_by?" do
		it "returns true for users equals to given parameter" do
			user = mock_model User
			subject.user = 	user
			subject.owned_by?(user).should be_true
		end

		it "returns false for users equals to given parameter" do
			user = mock_model User
			different_user = mock_model User
			subject.user = 	user
			subject.owned_by?(different_user).should be_false
		end
	end

	context "being destroyed" do
		it "destroys its collaborators"
	end
end

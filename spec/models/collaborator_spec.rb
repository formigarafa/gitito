require "spec_helper"

describe Collaborator do
  def valid_collaborator
    owner = User.new
    repository = Repository.new user: owner
    collaborator = User.new

    Collaborator.new user: collaborator, repository: repository
  end

  context "validity" do
    it "validates with valid attributes" do
      valid_collaborator.should be_valid
    end

    it "fails with no user" do
      collaborator = valid_collaborator
      collaborator.user = nil
      collaborator.should_not be_valid
    end

    it "fails with no repository" do
      collaborator = valid_collaborator
      collaborator.repository = nil
      collaborator.should_not be_valid
    end

    it "fails with duplicated user for the same repository" do
      repository = mock_model Repository
      repository.stub(:owned_by?).and_return(false)
      user = mock_model User
      collaborator = Collaborator.new user: user, repository: repository
      collaborator.save

      collaborator = Collaborator.new user: user, repository: repository
      collaborator.should_not be_valid
    end

    it "is valid for the same repository having different users" do
      repository = mock_model Repository
      repository.stub(:owned_by?).and_return(false)
      user1 = mock_model User
      user2 = mock_model User
      collaborator = Collaborator.new user: user1, repository: repository
      collaborator.save

      collaborator = Collaborator.new user: user2, repository: repository
      collaborator.should be_valid
    end

    it "is valid for differents repositories with the same user" do
      repository1 = mock_model Repository
      repository1.stub(:owned_by?).and_return(false)
      repository2 = mock_model Repository
      repository2.stub(:owned_by?).and_return(false)

      user = mock_model User
      collaborator = Collaborator.new user: user, repository: repository1
      collaborator.save

      collaborator = Collaborator.new user: user, repository: repository2
      collaborator.should be_valid
    end

    it "is not valid when user is owner of the repository" do
      collaborator = valid_collaborator
      collaborator.user = collaborator.repository.user
      collaborator.should_not be_valid
    end
  end
end

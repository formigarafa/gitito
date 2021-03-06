# frozen_string_literal: true

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
      expect(valid_collaborator).to be_valid
    end

    it "fails with no user" do
      collaborator = valid_collaborator
      collaborator.user = nil
      expect(collaborator).not_to be_valid
    end

    it "fails with no repository" do
      collaborator = valid_collaborator
      collaborator.repository = nil
      expect(collaborator).not_to be_valid
    end

    it "fails with duplicated user for the same repository" do
      repository = mock_model Repository
      allow(repository).to receive(:owned_by?).and_return(false)
      user = mock_model User
      collaborator = Collaborator.new user: user, repository: repository
      collaborator.save

      collaborator = Collaborator.new user: user, repository: repository
      expect(collaborator).not_to be_valid
    end

    it "is valid for the same repository having different users" do
      repository = mock_model Repository
      allow(repository).to receive(:owned_by?).and_return(false)
      user1 = mock_model User
      user2 = mock_model User
      collaborator = Collaborator.new user: user1, repository: repository
      collaborator.save

      collaborator = Collaborator.new user: user2, repository: repository
      expect(collaborator).to be_valid
    end

    it "is valid for differents repositories with the same user" do
      repository1 = mock_model Repository
      allow(repository1).to receive(:owned_by?).and_return(false)
      repository2 = mock_model Repository
      allow(repository2).to receive(:owned_by?).and_return(false)

      user = mock_model User
      collaborator = Collaborator.new user: user, repository: repository1
      collaborator.save

      collaborator = Collaborator.new user: user, repository: repository2
      expect(collaborator).to be_valid
    end

    it "is not valid when user is owner of the repository" do
      collaborator = valid_collaborator
      collaborator.user = collaborator.repository.user
      expect(collaborator).not_to be_valid
    end
  end
end

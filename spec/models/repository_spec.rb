# frozen_string_literal: true

require "spec_helper"

describe Repository do
  def valid_repo
    Repository.new name: "N4m3_W1th-V4l1d.Ch4r", user: mock_model(User, username: "juca")
  end

  context "validity" do
    it "validates with valid attributes" do
      expect(valid_repo).to be_valid
    end

    it "fails with no name" do
      repo = valid_repo
      repo.name = nil
      expect(repo).not_to be_valid
    end

    it "fails with no owner" do
      repo = valid_repo
      repo.user = nil
      expect(repo).not_to be_valid
    end

    it "fails with complicated name (special characters)" do
      repo = valid_repo
      repo.name = "f*cking_repo"
      expect(repo).not_to be_valid
    end

    it "fails with spaces on name" do
      repo = valid_repo
      repo.name = "some repo"
      expect(repo).not_to be_valid
    end

    it "is not allowed to one user have two repositories with the same name" do
      user = mock_model(User, username: "juca")
      repo1 = described_class.new
      allow(repo1).to receive(:create_structure)
      repo1.name = "same_name"
      repo1.user = user
      repo1.save

      repo2 = described_class.new
      allow(repo2).to receive(:create_structure)
      repo2.user = user
      repo2.name = "same_name"

      expect(repo2).not_to be_valid
    end

    it "is allowed for two different user have two repositories with the same name" do
      repo1 = described_class.new
      repo1.name = "same_name"
      allow(repo1).to receive(:create_structure)
      repo1.user = mock_model(User, username: "juca")
      repo1.save

      repo2 = described_class.new
      allow(repo2).to receive(:create_structure)
      repo2.user = mock_model(User, username: "drica.silva")
      repo2.name = "same_name"
      expect(repo2).to be_valid
    end
  end

  it "forbides repository name changes" do
    repo = valid_repo
    allow(repo).to receive(:create_structure)
    repo.save
    first_used_name = repo.name

    repo.name = "modified_name"
    repo.save

    repo.reload

    expect(repo.name).to eq first_used_name
  end

  context "path" do
    it "has method to get where I can find all repositories" do
      expect(described_class.repos_root).to eq "#{Rails.root}/db/users_repositories/#{Rails.env}"
    end

    it "has method to get repository path on file server" do
      repo = described_class.new name: "tilt", user: stub_model(User, username: "formigarafa")
      allow(described_class).to receive(:repos_root).and_return("/rOOt")
      expect(repo.server_path).to eq "/rOOt/formigarafa/tilt.git"
    end

    it "has method to get repository access url" do
      repo = described_class.new name: "tilt", user: stub_model(User, username: "formigarafa")
      allow(repo).to receive(:ssh_user).and_return("git")
      allow(repo).to receive(:ssh_host).and_return("gitito.com")

      expect(repo.url).to eq "git@gitito.com:formigarafa/tilt.git"
    end
  end

  context "file tree" do
    it "can check if there is a folder on repository place" do
      repo = described_class.new
      allow(repo).to receive(:server_path).and_return("#{Rails.root}/spec/fixtures/not_repo_test")

      expect(repo.folder_exists?).to be_truthy
    end

    it "can check if there is NOT a folder on repository place" do
      repo = described_class.new
      allow(repo).to receive(:server_path).and_return("#{Rails.root}/spec/fixtures/somewhere_else")

      expect(repo.folder_exists?).to be_falsey
    end

    it "can check if there is a repo placed" do
      repo = described_class.new
      expect(repo).to receive(:server_path).and_return("#{Rails.root}/spec/fixtures/repo_test.git")

      expect(repo.structure_ok?).to be_truthy
    end

    it "can check if there is NOT a repo placed" do
      repo = described_class.new
      expect(repo).to receive(:server_path).and_return("#{Rails.root}/spec/fixtures/none_repo_test.git")

      expect(repo.structure_ok?).to be_falsey
    end

    it "create repository tree when doesn't exist one" do
      Dir.mktmpdir do |tmp_dir|
        repo = described_class.new
        allow(repo).to receive(:server_path).and_return(tmp_dir + "/juca/repo_tmp")

        expect(repo.folder_exists?).to be_falsey
        repo.create_structure
        expect(repo.folder_exists?).to be_truthy
      end
    end

    it "does not create repository tree when exist something there" do
      Dir.mktmpdir do |_tmp_dir|
        repo = described_class.new

        allow(repo).to receive(:folder_exists?).and_return(true)
        allow(Rugged::Repository).to receive :init_at

        repo.create_structure
        expect(Rugged::Repository).not_to have_received :init_at
      end
    end

    it "removes structure folder" do
      Dir.mktmpdir do |tmp_dir|
        Dir.mkdir "#{tmp_dir}/1"
        Dir.mkdir "#{tmp_dir}/1/2"
        Dir.mkdir "#{tmp_dir}/1/2/3"

        repo = described_class.new
        allow(repo).to receive(:server_path).and_return("#{tmp_dir}/1")

        expect(repo.folder_exists?).to be_truthy
        repo.remove_structure

        expect(repo.folder_exists?).to be_falsey
      end
    end
  end

  context "being shared" do
    it "has many collaborators" do
      collaborators = [mock_model(Collaborator), mock_model(Collaborator)]
      collaborators.each do |collaborator|
        subject.collaborators << collaborator
      end

      # =~
      expect(subject.collaborators).to contain_exactly(*collaborators)
    end

    it "has no collaborators" do
      expect(subject.collaborators.size).to eq(0)
    end
  end

  context "method owned_by?" do
    it "returns true for users equals to given parameter" do
      user = mock_model User
      subject.user = user
      expect(subject.owned_by?(user)).to be_truthy
    end

    it "returns false for users equals to given parameter" do
      user = mock_model User
      different_user = mock_model User
      subject.user =   user
      expect(subject.owned_by?(different_user)).to be_falsey
    end
  end

  context "being destroyed" do
    it "destroys its collaborators"
  end
end

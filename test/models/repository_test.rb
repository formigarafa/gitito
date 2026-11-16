require "test_helper"

class RepositoryTest < ActiveSupport::TestCase
  def valid_repo
    Repository.new name: "N4m3_W1th-V4l1d.Ch4r", user: users(:juca)
  end

  # Saves the repository without touching the file system.
  def save_without_structure(repo)
    repo.stub(:create_structure, nil) { repo.save }
  end

  test "validates with valid attributes" do
    assert_predicate valid_repo, :valid?
  end

  test "fails with no name" do
    repo = valid_repo
    repo.name = nil
    assert_not repo.valid?
  end

  test "fails with no owner" do
    repo = valid_repo
    repo.user = nil
    assert_not repo.valid?
  end

  test "fails with complicated name (special characters)" do
    repo = valid_repo
    repo.name = "f*cking_repo"
    assert_not repo.valid?
  end

  test "fails with spaces on name" do
    repo = valid_repo
    repo.name = "some repo"
    assert_not repo.valid?
  end

  test "is not allowed to one user have two repositories with the same name" do
    user = users(:juca)
    assert save_without_structure(Repository.new(name: "same_name", user: user))

    repo2 = Repository.new name: "same_name", user: user
    assert_not repo2.valid?
  end

  test "is allowed for two different user have two repositories with the same name" do
    assert save_without_structure(Repository.new(name: "same_name", user: users(:juca)))

    repo2 = Repository.new name: "same_name", user: users(:drica)
    assert_predicate repo2, :valid?
  end

  test "forbides repository name changes" do
    repo = valid_repo
    assert save_without_structure(repo)
    first_used_name = repo.name

    assert_raises(ActiveRecord::ReadonlyAttributeError) { repo.name = "modified_name" }

    repo.reload

    assert_equal first_used_name, repo.name
  end

  test "has method to get where I can find all repositories" do
    assert_equal Rails.root.join("storage/repositories", Rails.env).to_s, Repository.repos_root
  end

  test "has method to get repository path on file server" do
    repo = Repository.new name: "tilt", user: users(:formigarafa)
    Repository.stub(:repos_root, "/rOOt") do
      assert_equal "/rOOt/formigarafa/tilt.git", repo.server_path
    end
  end

  test "has method to get repository access url" do
    repo = Repository.new name: "tilt", user: users(:formigarafa)
    repo.stub(:ssh_user, "git") do
      repo.stub(:ssh_host, "gitito.com") do
        assert_equal "git@gitito.com:formigarafa/tilt.git", repo.url
      end
    end
  end

  test "can check if there is a folder on repository place" do
    repo = Repository.new
    repo.stub(:server_path, file_fixture("not_repo_test").to_s) do
      assert_predicate repo, :folder_exists?
    end
  end

  test "can check if there is NOT a folder on repository place" do
    repo = Repository.new
    repo.stub(:server_path, Pathname(file_fixture_path).join("somewhere_else").to_s) do
      assert_not repo.folder_exists?
    end
  end

  test "can check if there is a repo placed" do
    repo = Repository.new
    repo.stub(:server_path, file_fixture("repo_test.git").to_s) do
      assert repo.structure_ok?
    end
  end

  test "can check if there is NOT a repo placed" do
    repo = Repository.new
    repo.stub(:server_path, Pathname(file_fixture_path).join("none_repo_test.git").to_s) do
      assert_not repo.structure_ok?
    end
  end

  test "create repository tree when doesn't exist one" do
    Dir.mktmpdir do |tmp_dir|
      repo = Repository.new
      repo.stub(:server_path, "#{tmp_dir}/juca/repo_tmp") do
        assert_not repo.folder_exists?
        repo.create_structure
        assert_predicate repo, :folder_exists?
      end
    end
  end

  test "does not create repository tree when exist something there" do
    repo = Repository.new
    init_called = false

    repo.stub(:folder_exists?, true) do
      Rugged::Repository.stub(:init_at, ->(*) { init_called = true }) do
        repo.create_structure
      end
    end

    assert_not init_called, "expected Rugged::Repository.init_at not to be called"
  end

  test "removes structure folder" do
    Dir.mktmpdir do |tmp_dir|
      FileUtils.mkdir_p "#{tmp_dir}/1/2/3"

      repo = Repository.new
      repo.stub(:server_path, "#{tmp_dir}/1") do
        assert_predicate repo, :folder_exists?
        repo.remove_structure

        assert_not repo.folder_exists?
      end
    end
  end

  test "has many collaborators" do
    repo = Repository.new
    collaborators = [ Collaborator.new, Collaborator.new ]
    collaborators.each do |collaborator|
      repo.collaborators << collaborator
    end

    assert_equal collaborators, repo.collaborators.to_a
  end

  test "has no collaborators" do
    assert_equal 0, Repository.new.collaborators.size
  end

  test "owned_by? returns true for users equals to given parameter" do
    user = users(:juca)
    repo = Repository.new user: user
    assert repo.owned_by?(user)
  end

  test "owned_by? returns false for users different from given parameter" do
    repo = Repository.new user: users(:juca)
    assert_not repo.owned_by?(users(:drica))
  end

  test "being destroyed destroys its collaborators" do
    skip "Not yet implemented"
  end
end

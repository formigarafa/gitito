require "test_helper"

class RepositoryTest < ActiveSupport::TestCase
  def valid_repo
    Repository.new name: "N4m3_W1th-V4l1d.Ch4r", user: users(:juca)
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
    assert Repository.new(name: "same_name", user: user).save

    repo2 = Repository.new name: "same_name", user: user
    assert_not repo2.valid?
  end

  test "is allowed for two different user have two repositories with the same name" do
    assert Repository.new(name: "same_name", user: users(:juca)).save

    repo2 = Repository.new name: "same_name", user: users(:drica)
    assert_predicate repo2, :valid?
  end

  test "forbides repository name changes" do
    repo = valid_repo
    assert repo.save
    first_used_name = repo.name

    assert_raises(ActiveRecord::ReadonlyAttributeError) { repo.name = "modified_name" }

    repo.reload

    assert_equal first_used_name, repo.name
  end

  test "has method to get repository access url" do
    repo = Repository.new name: "tilt", user: users(:formigarafa)
    repo.stub(:ssh_user, "git") do
      repo.stub(:ssh_host, "gitito.com") do
        assert_equal "git@gitito.com:formigarafa/tilt.git", repo.url
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

  test "has the path of a repository inside the repositories root" do
    assert_equal "formigarafa/tilt.git", repositories(:tilt).relative_path
  end

  test "is found by the path it has" do
    Repository.find_each do |repository|
      assert_equal repository, Repository.find_by_relative_path(repository.relative_path)
    end
  end

  test "is found by the name of its owner, not of a namesake repository" do
    namesake = Repository.create!(name: "tilt", user: users(:juca))

    assert_equal namesake, Repository.find_by_relative_path("juca/tilt.git")
    assert_equal repositories(:tilt), Repository.find_by_relative_path("formigarafa/tilt.git")
  end

  test "is found with every character a username and a name can have" do
    owner = User.create!(username: "N4m3_W1th-V4l1d.Ch4r", email: "owner@example.com", password: "1qaz2wsx")
    repository = Repository.create!(name: "N4m3_W1th-V4l1d.Ch4r.git", user: owner)

    assert_equal "N4m3_W1th-V4l1d.Ch4r/N4m3_W1th-V4l1d.Ch4r.git.git", repository.relative_path
    assert_equal repository, Repository.find_by_relative_path(repository.relative_path)
  end

  test "is not found by what is not the path of a repository" do
    [ nil, "", "tilt.git", "formigarafa/tilt", "formigarafa/nothing.git", "nobody/tilt.git",
      "formigarafa/tilt.git/", "/formigarafa/tilt.git", "x/formigarafa/tilt.git", "formigarafa/tilt.git\n",
      "formigarafa/.git", "formi garafa/tilt.git", "formigarafa/ti*lt.git" ].each do |path|
      assert_nil Repository.find_by_relative_path(path), "expected #{path.inspect} not to find a repository"
    end
  end

  test "is accessible by its owner and its collaborators only" do
    repo = repositories(:tilt)
    repo.collaborators.create!(user: users(:juca))

    assert repo.accessible_by?(users(:formigarafa))
    assert repo.accessible_by?(users(:juca))
    assert_not repo.accessible_by?(users(:drica))
    assert_not repo.accessible_by?(nil)
  end

  test "being destroyed destroys its collaborators" do
    repo = repositories(:tilt)
    repo.collaborators.create!(user: users(:juca))
    repo.collaborators.create!(user: users(:drica))

    assert_difference -> { Collaborator.count }, -2 do
      repo.destroy!
    end
  end

  test "reads the ssh user and host from the gitito configuration" do
    repo = Repository.new
    assert_equal Rails.configuration.gitito[:ssh_user], repo.ssh_user
    assert_equal Rails.configuration.gitito[:ssh_host], repo.ssh_host
  end

  test "builds the url with the configured ssh user and host" do
    repo = Repository.new name: "tilt", user: users(:formigarafa)
    config = Rails.configuration.gitito
    assert_equal "#{config[:ssh_user]}@#{config[:ssh_host]}:formigarafa/tilt.git", repo.url
  end

  test "being created stores a git repository" do
    repo = Repository.create! name: "fresh", user: users(:juca)

    assert_stored repo
  end

  test "failing to be created stores nothing" do
    repo = Repository.create name: "not valid!", user: users(:juca)

    assert_not repo.persisted?
    assert_empty Dir.children(RepositoryStorage.default.root)
  end

  test "is not created over data left where it would be stored" do
    repo = Repository.new name: "leftover", user: users(:juca)
    FileUtils.mkdir_p storage_path_of(repo)

    assert_not repo.save
    assert_not repo.persisted?
    assert_includes repo.errors[:name], "is taken by data left on the server"
    assert_not Repository.exists?(name: "leftover")
    assert_empty Dir.children(storage_path_of(repo))
  end

  test "being destroyed removes what it stored" do
    repo = Repository.create! name: "doomed", user: users(:juca)

    repo.destroy!

    assert_not_stored repo
  end

  test "a creation that is rolled back stores nothing" do
    repo = nil

    Repository.transaction do
      repo = Repository.create! name: "undone", user: users(:juca)
      assert_stored repo
      raise ActiveRecord::Rollback
    end

    assert_not Repository.exists?(name: "undone")
    assert_empty Dir.children(RepositoryStorage.default.root)
  end

  test "a change that is rolled back after the creation keeps what is stored" do
    repo = Repository.create! name: "settled", user: users(:juca)

    Repository.transaction do
      repo.touch
      raise ActiveRecord::Rollback
    end

    assert_stored repo
  end

  test "a destruction that is rolled back keeps what is stored" do
    repo = Repository.create! name: "spared", user: users(:juca)

    Repository.transaction do
      repo.destroy!
      raise ActiveRecord::Rollback
    end

    assert Repository.exists?(name: "spared")
    assert_stored repo
  end

  test "being destroyed keeps the other repositories of its owner" do
    doomed = Repository.create! name: "doomed", user: users(:juca)
    kept = Repository.create! name: "kept", user: users(:juca)

    doomed.destroy!

    assert_stored kept
  end
end

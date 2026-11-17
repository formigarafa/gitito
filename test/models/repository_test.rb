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

  test "being destroyed keeps the other repositories of its owner" do
    doomed = Repository.create! name: "doomed", user: users(:juca)
    kept = Repository.create! name: "kept", user: users(:juca)

    doomed.destroy!

    assert_stored kept
  end
end

require "test_helper"

class CollaboratorTest < ActiveSupport::TestCase
  def valid_collaborator
    owner = User.new
    repository = Repository.new user: owner
    collaborator = User.new

    Collaborator.new user: collaborator, repository: repository
  end

  test "validates with valid attributes" do
    assert_predicate valid_collaborator, :valid?
  end

  test "fails with no user" do
    collaborator = valid_collaborator
    collaborator.user = nil
    assert_not collaborator.valid?
  end

  test "fails with no repository" do
    collaborator = valid_collaborator
    collaborator.repository = nil
    assert_not collaborator.valid?
  end

  test "fails with duplicated user for the same repository" do
    repository = repositories(:tilt)
    user = users(:juca)
    Collaborator.create! user: user, repository: repository

    collaborator = Collaborator.new user: user, repository: repository
    assert_not collaborator.valid?
  end

  test "is valid for the same repository having different users" do
    repository = repositories(:tilt)
    Collaborator.create! user: users(:juca), repository: repository

    collaborator = Collaborator.new user: users(:drica), repository: repository
    assert_predicate collaborator, :valid?
  end

  test "is valid for differents repositories with the same user" do
    user = users(:juca)
    Collaborator.create! user: user, repository: repositories(:tilt)

    collaborator = Collaborator.new user: user, repository: repositories(:rails)
    assert_predicate collaborator, :valid?
  end

  test "is not valid when user is owner of the repository" do
    collaborator = valid_collaborator
    collaborator.user = collaborator.repository.user
    assert_not collaborator.valid?
  end

  test "explains that the user was not found" do
    collaborator = Collaborator.new repository: repositories(:tilt)
    assert_not collaborator.valid?
    assert_equal [ "User not found" ], collaborator.errors.map(&:message)
  end

  test "explains that the repository was not found" do
    collaborator = Collaborator.new user: users(:juca)
    assert_not collaborator.valid?
    assert_equal [ "Repository not found" ], collaborator.errors.map(&:message)
  end

  test "explains that the owner cannot be a collaborator" do
    collaborator = Collaborator.new user: users(:formigarafa), repository: repositories(:tilt)
    assert_not collaborator.valid?
    assert_equal [ "Repository owner cannot be also a collaborator" ], collaborator.errors.map(&:message)
  end

  test "explains that the user already is a collaborator" do
    Collaborator.create! user: users(:juca), repository: repositories(:tilt)

    collaborator = Collaborator.new user: users(:juca), repository: repositories(:tilt)
    assert_not collaborator.valid?
    assert_equal [ "Collaborator is already on the list" ], collaborator.errors.map(&:message)
  end

  test "has the username of its user" do
    assert_equal "juca", Collaborator.new(user: users(:juca)).username
  end

  test "has no username without a user" do
    assert_nil Collaborator.new.username
  end

  test "knows when its user owns the repository" do
    repository = repositories(:tilt)

    assert Collaborator.new(user: users(:formigarafa), repository: repository).collaborator_owns_repository?
    assert_not Collaborator.new(user: users(:juca), repository: repository).collaborator_owns_repository?
    assert_not Collaborator.new(user: users(:juca)).collaborator_owns_repository?
  end
end

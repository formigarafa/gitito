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
end

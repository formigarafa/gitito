require "test_helper"

class SshAccessTest < ActiveSupport::TestCase
  def add_key(user)
    user.user_credentials.create!(key: "ssh-ed25519 AAAA#{SecureRandom.hex} #{user.username}")
  end

  test "allows the keys of the owner" do
    assert SshAccess.allowed?(add_key(users(:formigarafa)).id, "formigarafa/tilt.git")
  end

  test "allows the keys of a collaborator, until they are removed" do
    key = add_key(users(:juca))
    collaborator = repositories(:tilt).collaborators.create!(user: users(:juca))

    assert SshAccess.allowed?(key.id, "formigarafa/tilt.git")
    assert_not SshAccess.allowed?(key.id, "formigarafa/rails.git")

    collaborator.destroy!
    assert_not SshAccess.allowed?(key.id, "formigarafa/tilt.git")
  end

  test "does not allow the keys of other users" do
    assert_not SshAccess.allowed?(add_key(users(:drica)).id, "formigarafa/tilt.git")
  end

  test "does not allow a key that was removed" do
    key = add_key(users(:formigarafa))
    key.destroy!

    assert_not SshAccess.allowed?(key.id, "formigarafa/tilt.git")
  end

  test "does not allow what is not the path of a repository" do
    key = add_key(users(:formigarafa))

    [ nil, "", "tilt.git", "formigarafa/tilt", "formigarafa/nothing.git", "nobody/tilt.git",
      "formigarafa/tilt.git/", "x/formigarafa/tilt.git", "formigarafa/tilt.git\n" ].each do |path|
      assert_not SshAccess.allowed?(key.id, path), "expected #{path.inspect} not to be allowed"
    end
  end

  test "finds a repository by the name of its owner, not of a namesake repository" do
    namesake = Repository.create!(name: "tilt", user: users(:juca))

    assert_equal namesake, SshAccess.find_repository("juca/tilt.git")
    assert_equal repositories(:tilt), SshAccess.find_repository("formigarafa/tilt.git")
  end

  test "has a token that stays the same and tells others apart" do
    assert_match(/\A\h{64}\z/, SshAccess.token)
    assert_equal SshAccess.token, SshAccess.token
    assert SshAccess.valid_token?(SshAccess.token)
    assert_not SshAccess.valid_token?("#{SshAccess.token}0")
    assert_not SshAccess.valid_token?("")
    assert_not SshAccess.valid_token?(nil)
  end
end

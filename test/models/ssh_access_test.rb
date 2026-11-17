require "test_helper"

class SshAccessTest < ActiveSupport::TestCase
  NOT_FOUND = "Repository not found or access denied".freeze
  NOT_ALLOWED = "Command not allowed".freeze

  def add_key(user)
    user.user_credentials.create!(key: ssh_key(user.username))
  end

  def assert_granted(verb, repository, credential, command)
    assert_equal SshAccess::Grant.new(verb: verb, repository: repository), SshAccess.decide(credential.id, command)
  end

  def assert_denied(message, credential_id, command)
    assert_equal SshAccess::Denial.new(message: message), SshAccess.decide(credential_id, command),
      "expected #{command.inspect} to be denied"
  end

  test "lets the keys of the owner fetch from and push to the repository" do
    key = add_key(users(:formigarafa))

    assert_granted "git-upload-pack", "formigarafa/tilt.git", key, "git-upload-pack 'formigarafa/tilt.git'"
    assert_granted "git-receive-pack", "formigarafa/tilt.git", key, "git-receive-pack 'formigarafa/tilt.git'"
    assert_granted "git-upload-archive", "formigarafa/rails.git", key, "git-upload-archive 'formigarafa/rails.git'"
  end

  test "lets the keys of the owner run what git sends for the url of the repository" do
    key = add_key(users(:formigarafa))
    path = repositories(:tilt).url.split(":", 2).last

    assert_granted "git-upload-pack", "formigarafa/tilt.git", key, "git-upload-pack '#{path}'"
  end

  test "tells a grant from a denial" do
    key = add_key(users(:formigarafa))

    assert_predicate SshAccess.decide(key.id, "git-upload-pack 'formigarafa/tilt.git'"), :granted?
    assert_not SshAccess.decide(key.id, "git-upload-pack 'formigarafa/nothing.git'").granted?
  end

  test "understands the other ways git writes the same request" do
    key = add_key(users(:formigarafa))

    [ "git upload-pack 'formigarafa/tilt.git'", "git-upload-pack '/formigarafa/tilt.git'",
      "git-upload-pack 'formigarafa/tilt'", "git-upload-pack formigarafa/tilt.git",
      "git upload-pack /formigarafa/tilt" ].each do |command|
      assert_granted "git-upload-pack", "formigarafa/tilt.git", key, command
    end
  end

  test "lets the keys of a collaborator in, until they are removed" do
    key = add_key(users(:juca))
    collaborator = repositories(:tilt).collaborators.create!(user: users(:juca))

    assert_granted "git-receive-pack", "formigarafa/tilt.git", key, "git-receive-pack 'formigarafa/tilt.git'"
    assert_denied NOT_FOUND, key.id, "git-receive-pack 'formigarafa/rails.git'"

    collaborator.destroy!
    assert_denied NOT_FOUND, key.id, "git-receive-pack 'formigarafa/tilt.git'"
  end

  test "denies the keys of other users" do
    assert_denied NOT_FOUND, add_key(users(:drica)).id, "git-upload-pack 'formigarafa/tilt.git'"
  end

  test "denies a key that was removed, or that never was" do
    key = add_key(users(:formigarafa))
    key.destroy!

    assert_denied NOT_FOUND, key.id, "git-upload-pack 'formigarafa/tilt.git'"
    assert_denied NOT_FOUND, 0, "git-upload-pack 'formigarafa/tilt.git'"
    assert_denied NOT_FOUND, nil, "git-upload-pack 'formigarafa/tilt.git'"
  end

  test "denies a repository that does not exist the same way as one out of reach" do
    key = add_key(users(:formigarafa))

    assert_denied NOT_FOUND, key.id, "git-upload-pack 'formigarafa/nothing.git'"
    assert_denied NOT_FOUND, key.id, "git-upload-pack 'nobody/tilt.git'"
  end

  test "denies paths that are not of a repository" do
    key = add_key(users(:formigarafa))

    [ "git-upload-pack 'formigarafa/tilt.git' 'formigarafa/rails.git'",
      "git-upload-pack 'formigarafa/tilt.git'; cat /etc/passwd",
      "git-upload-pack 'formigarafa/tilt.git\n'",
      "git-upload-pack 'formigarafa/tilt.git&credential_id=2'",
      "git-upload-pack 'formigarafa/tilt.git/'",
      "git-upload-pack '//formigarafa/tilt.git'",
      "git-upload-pack 'x/formigarafa/tilt.git'",
      "git-upload-pack '../formigarafa/tilt.git'",
      "git-upload-pack 'tilt.git'",
      "git-upload-pack ''",
      "git-upload-pack ",
      "git-upload-pack" ].each do |command|
      assert_denied NOT_FOUND, key.id, command
    end
  end

  test "denies anything that is not a git server command" do
    key = add_key(users(:formigarafa))

    [ "ls", "cvs server", "git status", "git-shell 'formigarafa/tilt.git'", " git-upload-pack 'formigarafa/tilt.git'",
      "GIT-UPLOAD-PACK 'formigarafa/tilt.git'", "git  upload-pack 'formigarafa/tilt.git'", "", nil ].each do |command|
      assert_denied NOT_ALLOWED, key.id, command
    end
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

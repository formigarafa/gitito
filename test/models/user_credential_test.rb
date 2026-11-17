require "test_helper"

class UserCredentialTest < ActiveSupport::TestCase
  def valid_credential
    UserCredential.new(title: "test key", key: ssh_key("user@comment.part.com"), user: users(:juca))
  end

  def authorized_keys
    File.read(SshFiles.default.authorized_keys)
  end

  test "validates with valid attributes" do
    assert_predicate valid_credential, :valid?
  end

  test "fails with no user" do
    credential = valid_credential
    credential.user = nil
    assert_not credential.valid?
  end

  test "fails with no key" do
    credential = valid_credential
    credential.key = ""
    assert_not credential.valid?
  end

  test "fails for a key someone else has" do
    taken = valid_credential
    taken.save!

    credential = UserCredential.new(key: taken.key, user: users(:drica))

    assert_not credential.valid?
    assert_equal [ "has already been taken" ], credential.errors[:key]
  end

  test "fails for a key someone else has under another comment" do
    type, body = ssh_key.split
    UserCredential.create!(key: "#{type} #{body} mine", user: users(:juca))

    assert_not UserCredential.new(key: "#{type} #{body} also mine", user: users(:drica)).valid?
  end

  test "keeps its key when saved again" do
    credential = valid_credential
    credential.save!

    assert credential.update(title: "renamed")
  end

  test "fails for what is not a public key" do
    credential = valid_credential
    credential.key = "ssh-ed25519 AAAA not-a-key"

    assert_not credential.valid?
    assert_equal [ "is not an SSH public key" ], credential.errors[:key]
  end

  test "fails for a key followed by another line" do
    credential = valid_credential
    credential.key = "#{ssh_key}\n#{ssh_key}"

    assert_not credential.valid?
  end

  test "keeps the key in one line, without the blanks around it" do
    key = ssh_key("juca@laptop")
    credential = valid_credential
    credential.key = "  #{key}\r\n"

    assert_predicate credential, :valid?
    assert_equal key, credential.key
  end

  test "being created adds its key to the authorized_keys file" do
    credential = valid_credential
    credential.save!

    assert_includes authorized_keys, credential.key
  end

  test "being updated changes its key on the authorized_keys file" do
    credential = valid_credential
    credential.save!
    previous_key = credential.key
    changed = ssh_key("changed")
    credential.update!(key: changed)

    assert_includes authorized_keys, changed
    assert_not_includes authorized_keys, previous_key
  end

  test "being destroyed removes its key from the authorized_keys file" do
    kept = valid_credential
    doomed = valid_credential
    [ kept, doomed ].each(&:save!)

    doomed.destroy!

    assert_includes authorized_keys, kept.key
    assert_not_includes authorized_keys, doomed.key
  end

  test "failing to be saved leaves the authorized_keys file untouched" do
    FileUtils.rm_f SshFiles.default.authorized_keys

    assert_not UserCredential.new(title: "no key", user: users(:juca)).save

    assert_not File.exist?(SshFiles.default.authorized_keys)
  end

  test "being rolled back leaves the authorized_keys file untouched" do
    FileUtils.rm_f SshFiles.default.authorized_keys

    UserCredential.transaction do
      valid_credential.save!
      raise ActiveRecord::Rollback
    end

    assert_not File.exist?(SshFiles.default.authorized_keys)
  end

  test "does not require a title" do
    credential = valid_credential
    credential.title = nil
    assert_predicate credential, :valid?
  end
end

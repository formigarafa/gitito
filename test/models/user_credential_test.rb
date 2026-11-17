require "test_helper"

class UserCredentialTest < ActiveSupport::TestCase
  BASE64_CHARSET = [ *"a".."z", *"A".."Z", *"0".."9", "+", "/" ].freeze

  def valid_credential
    key = "ssh-rsa #{Array.new(372) { BASE64_CHARSET.sample }.join} user@comment.part.com"
    UserCredential.new(
      title: "test key",
      key: key,
      user: users(:juca),
    )
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

  test "fails for duplicated keys" do
    user = users(:juca)
    key = [
      "ssh-rsa ",
      "AAAAB3NzaC1yc2EAAAADAQABAAABAQC4d8XdRasriu5HA/GrmNv6wM50TioIgjsW/NcuVnH",
      "fuF29SGZkb1mjodDkKVP7BboGIfyE1SG4mgAxv8VGtN3FBtSZPWPCD1zOGwg/uFgbugYgWR",
      "Lg8IVKoSdDSgG7YwdLF7fktjpUCidFAaYCBnkzDkw+tWt9y79IdgokRwK+bmVuf80xXAr6m",
      "D9WLNqTxqXdmCHd9cMePzszdIVUtjIk0R/YHaoCZat+T2D+ICLs2oz2lv+4z5A6who82u6d",
      "0X5HDV7dIxf5s8rb/8HGbU1hshsK7VE6SXzph/dj7otkl4Mq4bJ3yLx6l7YktZ9hmVsn+S0",
      "zKcnlasD+ND2LM30X user@comment.part.com"
    ].join

    credential1 = valid_credential
    credential1.key = key
    credential1.user = user
    assert credential1.save

    credential2 = valid_credential
    credential2.user = user
    credential2.key = key

    assert_not credential2.valid?
  end

  # ref: http://stackoverflow.com/questions/2494450/ssh-rsa-public-key-validation-using-a-regular-expression
  # latter, dont'botter me, yet.
  # test "fails with no spaces separating fields"
  # test "fails when first field not in [ssh-rsa, ssh-dsa]"
  # test "fails when second field can't be base64 decoded"
  # test "fails when decoded second field has wrong leading"

  test "being created adds its key to the authorized_keys file" do
    credential = valid_credential
    credential.save!

    assert_includes authorized_keys, credential.key
  end

  test "being updated changes its key on the authorized_keys file" do
    credential = valid_credential
    credential.save!
    previous_key = credential.key
    credential.update!(key: "ssh-ed25519 AAAA changed")

    assert_includes authorized_keys, "ssh-ed25519 AAAA changed"
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

  test "does not require a title" do
    credential = valid_credential
    credential.title = nil
    assert_predicate credential, :valid?
  end
end

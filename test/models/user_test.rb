require "test_helper"

class UserTest < ActiveSupport::TestCase
  def valid_user
    User.new username: "N4m3_W1th-V4l1d.Ch4r", email: "anyone@somedomain.com", password: "1qaz2wsx"
  end

  test "validates with valid attributes" do
    assert_predicate valid_user, :valid?
  end

  test "validates with matching password_confirmation" do
    user = valid_user
    user.password = "p4ssw0rd"
    user.password_confirmation = "p4ssw0rd"
    assert_predicate user, :valid?
  end

  test "fails with no username" do
    user = valid_user
    user.username = nil
    assert_not user.valid?
  end

  test "fails with no email" do
    user = valid_user
    user.email = nil
    assert_not user.valid?
  end

  test "fails with no password" do
    user = valid_user
    user.password = nil
    assert_not user.valid?
  end

  test "fails when password does not match password_confirmation" do
    user = valid_user
    user.password = "1qaz2wsx"
    user.password_confirmation = "0okm9ijn"
    assert_not user.valid?
  end

  test "fails with a password shorter than 6 characters" do
    user = valid_user
    user.password = "12345"
    assert_not user.valid?
  end

  test "fails with a malformed email" do
    user = valid_user
    user.email = "not an email"
    assert_not user.valid?
  end

  test "fails with an email already taken, whatever the case" do
    user = valid_user
    user.email = users(:juca).email.upcase
    assert_not user.valid?
  end

  test "normalizes the email" do
    assert_equal "anyone@somedomain.com", User.new(email: " Anyone@SomeDomain.com ").email
  end

  test "authenticates with the right password only" do
    user = users(:juca)
    assert_equal user, user.authenticate("password")
    assert_not user.authenticate("wrong")
  end

  test "authenticates passwords hashed by devise and rehashes them" do
    user = users(:juca)
    devise_digest = BCrypt::Password.create("0ldp4ssw0rd#{User::DEVISE_PEPPER}", cost: BCrypt::Engine::MIN_COST).to_s
    user.update_column(:password_digest, devise_digest)

    assert_not user.authenticate("wrong")
    assert_equal devise_digest, user.reload.password_digest

    assert_equal user, User.authenticate_by(email: user.email, password: "0ldp4ssw0rd")
    assert_not_equal devise_digest, user.reload.password_digest
    assert BCrypt::Password.new(user.password_digest).is_password?("0ldp4ssw0rd")
  end

  test "being destroyed destroys its sessions" do
    user = users(:drica)
    user.sessions.create!
    assert_difference -> { Session.count }, -1 do
      user.destroy!
    end
  end

  test "fails with complicated username (special characters)" do
    user = valid_user
    user.username = "f*cking_user"
    assert_not user.valid?
  end

  test "fails with spaces on username" do
    user = valid_user
    user.username = "some user name"
    assert_not user.valid?
  end

  test "being destroyed destroys its credentials" do
    skip "Not yet implemented"
  end

  test "being destroyed destroys collaborative presence on third party repositories" do
    skip "Not yet implemented"
  end

  test "being destroyed destroys its repositories" do
    skip "Not yet implemented" # think about it...
  end

  test "has relations with collaborative repositories" do
    skip "Not yet implemented"
  end

  test "generates gravatar url from user email" do
    skip "Not yet implemented"
  end
end

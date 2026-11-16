# frozen_string_literal: true

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

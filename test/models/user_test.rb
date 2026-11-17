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

  test "fails with the username of another user" do
    user = valid_user
    user.username = users(:juca).username
    assert_not user.valid?
    assert_includes user.errors[:username], "has already been taken"
  end

  test "fails with a username that points to another folder or reads as an option" do
    %w[. .. .hidden -juca --strict].each do |username|
      user = valid_user
      user.username = username
      assert_not user.valid?, "expected #{username.inspect} to be refused"
    end
  end

  test "forbids username changes, which would leave its repositories behind" do
    user = users(:formigarafa)

    assert_raises(ActiveRecord::ReadonlyAttributeError) { user.username = "renamed" }
    assert_equal "formigarafa", user.reload.username
    assert_equal repositories(:tilt), Repository.find_by_relative_path("formigarafa/tilt.git")
  end

  test "validates with dots, dashes and underscores after the first character of the username" do
    user = valid_user
    user.username = "9a-b_c.d"
    assert_predicate user, :valid?
  end

  test "fails with a blank username" do
    user = valid_user
    user.username = ""
    assert_not user.valid?
    assert_includes user.errors[:username], "can't be blank"
  end

  test "being destroyed destroys its credentials" do
    user = users(:drica)
    user.user_credentials.create!(title: "laptop", key: ssh_key("drica"))

    assert_difference -> { UserCredential.count }, -1 do
      user.destroy!
    end
  end

  test "being destroyed destroys collaborative presence on third party repositories" do
    user = users(:drica)
    repositories(:tilt).collaborators.create!(user: user)

    assert_difference -> { repositories(:tilt).collaborators.count }, -1 do
      user.destroy!
    end
  end

  test "cannot be destroyed while it owns repositories" do
    user = users(:formigarafa)

    assert_no_difference [ -> { User.count }, -> { Repository.count } ] do
      assert_not user.destroy
    end
    assert_includes user.errors.full_messages, "Cannot delete record because dependent repositories exist"
  end

  test "has relations with collaborative repositories" do
    user = users(:drica)
    relation = repositories(:tilt).collaborators.create!(user: user)

    assert_equal [ relation ], user.collaborative_relations.to_a
    assert_equal [ repositories(:tilt) ], user.collaborative_relations.map(&:repository)
    assert_empty users(:juca).collaborative_relations
  end

  test "has the repositories it owns" do
    assert_equal repositories(:tilt, :rails).sort_by(&:id), users(:formigarafa).repositories.sort_by(&:id)
    assert_empty users(:juca).repositories
  end

  test "generates gravatar url from user email" do
    user = User.new email: "juca@example.com"
    assert_equal "http://www.gravatar.com/avatar/#{Digest::MD5.hexdigest('juca@example.com')}", user.gravatar_url
  end

  test "gravatar url ignores case and surrounding spaces in the email" do
    assert_equal User.new(email: "juca@example.com").gravatar_url, User.new(email: " Juca@Example.com ").gravatar_url
  end

  test "tracks the first sign in" do
    user = users(:juca)

    freeze_time do
      user.track_sign_in("10.0.0.1")
      user.reload

      assert_equal 1, user.sign_in_count
      assert_equal Time.current, user.current_sign_in_at
      assert_equal Time.current, user.last_sign_in_at
      assert_equal "10.0.0.1", user.current_sign_in_ip
      assert_equal "10.0.0.1", user.last_sign_in_ip
    end
  end

  test "tracking a later sign in keeps the previous one as the last sign in" do
    user = users(:juca)
    first_sign_in_at = 3.days.ago.change(usec: 0)
    travel_to(first_sign_in_at) { user.track_sign_in("10.0.0.1") }

    freeze_time do
      user.track_sign_in("10.0.0.2")
      user.reload

      assert_equal 2, user.sign_in_count
      assert_equal Time.current, user.current_sign_in_at
      assert_equal first_sign_in_at, user.last_sign_in_at
      assert_equal "10.0.0.2", user.current_sign_in_ip
      assert_equal "10.0.0.1", user.last_sign_in_ip
    end
  end

  test "tracking a sign in does not touch updated_at" do
    user = users(:juca)
    assert_no_changes -> { user.reload.updated_at } do
      user.track_sign_in("10.0.0.1")
    end
  end

  test "is found by its password reset token until the password changes" do
    user = users(:juca)
    token = user.password_reset_token

    assert_equal user, User.find_by_password_reset_token(token)

    user.update!(password: "n3wp4ss")
    assert_nil User.find_by_password_reset_token(token)
  end

  test "password reset token expires after two hours" do
    user = users(:juca)
    token = user.password_reset_token

    travel(2.hours - 1.minute) { assert_equal user, User.find_by_password_reset_token(token) }
    travel(2.hours + 1.minute) { assert_nil User.find_by_password_reset_token(token) }
  end
end

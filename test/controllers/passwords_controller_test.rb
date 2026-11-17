require "test_helper"

class PasswordsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:juca) }

  test "new" do
    get new_password_path
    assert_response :success
  end

  test "create" do
    post passwords_path, params: { email: @user.email }
    assert_enqueued_email_with PasswordsMailer, :reset, args: [ @user ]
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "create for an unknown user redirects but sends no mail" do
    post passwords_path, params: { email: "missing-user@example.com" }
    assert_enqueued_emails 0
    assert_redirected_to new_session_path

    follow_redirect!
    assert_notice "reset instructions sent"
  end

  test "edit" do
    get edit_password_path(@user.password_reset_token)
    assert_response :success
  end

  test "edit with invalid password reset token" do
    get edit_password_path("invalid token")
    assert_redirected_to new_password_path

    follow_redirect!
    assert_notice "reset link is invalid"
  end

  test "edit with a token older than two hours" do
    token = @user.password_reset_token

    travel 2.hours + 1.minute do
      get edit_password_path(token)
      assert_redirected_to new_password_path
    end
  end

  test "update" do
    @user.sessions.create!

    assert_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "n3wp4ss", password_confirmation: "n3wp4ss" }
      assert_redirected_to new_session_path
    end
    assert_empty @user.sessions
    assert @user.authenticate("n3wp4ss")

    follow_redirect!
    assert_notice "password has been changed"
  end

  test "update makes the token unusable" do
    token = @user.password_reset_token
    put password_path(token), params: { password: "n3wp4ss", password_confirmation: "n3wp4ss" }

    get edit_password_path(token)
    assert_redirected_to new_password_path
  end

  test "update with non matching passwords" do
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "n3wp4ss", password_confirmation: "match" }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation li", text: "Password confirmation doesn't match Password"
  end

  test "update with a blank or short password" do
    assert_no_changes -> { @user.reload.password_digest } do
      put password_path(@user.password_reset_token), params: { password: "", password_confirmation: "" }
      assert_response :unprocessable_content

      put password_path(@user.password_reset_token), params: { password: "short", password_confirmation: "short" }
      assert_response :unprocessable_content
    end
  end

  private
    def assert_notice(text)
      assert_select ".flash .message", /#{text}/
    end
end

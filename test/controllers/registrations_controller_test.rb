require "test_helper"

class RegistrationsControllerTest < ActionDispatch::IntegrationTest
  setup { @user = users(:drica) }

  test "new" do
    get new_registration_path
    assert_response :success
    assert_select "form[action=?]", registration_path
  end

  test "create signs the new user in" do
    assert_difference -> { User.count } do
      post registration_path, params: { user: { username: "newbie", email: "Newbie@example.com", password: "1qaz2wsx" } }
    end

    assert_redirected_to root_path
    assert cookies[:session_id]
    assert_equal "newbie@example.com", User.find_by!(username: "newbie").email
  end

  test "create with invalid attributes" do
    assert_no_difference -> { User.count } do
      post registration_path, params: { user: { username: "not valid!", email: @user.email, password: "short" } }
    end

    assert_response :unprocessable_content
    assert_select "#error_explanation li", text: "Email has already been taken"
    assert_select "#error_explanation li", text: "Password is too short (minimum is 6 characters)"
    assert_select "#error_explanation li", text: "Username is invalid"
  end

  test "edit requires authentication" do
    get edit_registration_path
    assert_redirected_to new_session_path
  end

  test "edit" do
    sign_in_as @user

    get edit_registration_path
    assert_response :success
    assert_select "input[name=?][value=?]", "user[email]", @user.email
  end

  test "update changes the email with the current password" do
    sign_in_as @user

    put registration_path, params: { user: { email: "new@example.com", password: "", password_confirmation: "", password_challenge: "password" } }

    assert_redirected_to edit_registration_path
    assert_equal "new@example.com", @user.reload.email
    assert @user.authenticate("password")
  end

  test "update changes the password and signs out other sessions" do
    other_session = @user.sessions.create!
    sign_in_as @user

    put registration_path, params: { user: { email: @user.email, password: "n3wp4ss", password_confirmation: "n3wp4ss", password_challenge: "password" } }

    assert_redirected_to edit_registration_path
    assert @user.reload.authenticate("n3wp4ss")
    assert_not Session.exists?(other_session.id)

    get edit_registration_path
    assert_response :success
  end

  test "update without the current password" do
    sign_in_as @user

    [ "", "wrong" ].each do |challenge|
      put registration_path, params: { user: { email: "new@example.com", password: "n3wp4ss", password_confirmation: "n3wp4ss", password_challenge: challenge } }

      assert_response :unprocessable_content
      assert_select "#error_explanation li", text: "Current password is invalid"
    end
    put registration_path, params: { user: { email: "new@example.com" } }
    assert_response :unprocessable_content

    assert_equal "drica@example.com", @user.reload.email
    assert @user.authenticate("password")
  end

  test "update cannot change the username" do
    sign_in_as @user

    put registration_path, params: { user: { username: "hacked", password_challenge: "password" } }

    assert_equal "drica.silva", @user.reload.username
  end

  test "destroy cancels the account" do
    sign_in_as @user

    assert_difference -> { User.count }, -1 do
      delete registration_path
    end

    assert_redirected_to new_session_path
    assert_response :see_other
    assert_empty cookies[:session_id]
  end

  test "destroy keeps an account that still owns repositories" do
    owner = users(:formigarafa)
    sign_in_as owner

    assert_no_difference -> { User.count } do
      delete registration_path
    end

    assert_redirected_to edit_registration_path
    assert_predicate flash[:alert], :present?
    get edit_registration_path
    assert_response :success
  end
end

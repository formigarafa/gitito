require "test_helper"

class UserCredentialsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = users(:juca)
    sign_in_as @user
  end

  def without_authorized_keys_file(&)
    UserCredential.stub(:generate_authorized_keys_file, nil, &)
  end

  def create_credential(user = @user)
    without_authorized_keys_file do
      user.user_credentials.create!(title: "laptop", key: "ssh-ed25519 AAAA #{SecureRandom.hex(4)}")
    end
  end

  test "index lists only own credentials" do
    own = create_credential
    other = create_credential(users(:drica))
    other.update_column(:title, "someone else")

    get user_credentials_path

    assert_response :success
    assert_match own.title, response.body
    assert_no_match other.title, response.body
  end

  test "new renders the form" do
    get new_user_credential_path
    assert_response :success
    assert_select "form[action=?]", user_credentials_path
  end

  test "create builds the credential for the current user" do
    assert_difference -> { @user.user_credentials.count } do
      without_authorized_keys_file do
        post user_credentials_path, params: { user_credential: { title: "laptop", key: "ssh-ed25519 AAAA new" } }
      end
    end
    assert_redirected_to user_credentials_path
    assert_response :see_other
    assert_equal "User credential was successfully created.", flash[:notice]
  end

  test "create with invalid params renders the form with 422" do
    assert_no_difference -> { UserCredential.count } do
      post user_credentials_path, params: { user_credential: { title: "laptop", key: "" } }
    end
    assert_response :unprocessable_content
    assert_select "#error_explanation"
  end

  test "edit renders the form for an own credential" do
    credential = create_credential
    get edit_user_credential_path(credential)
    assert_response :success
    assert_select "form[action=?]", user_credential_path(credential)
  end

  test "edit does not find credentials of other users" do
    credential = create_credential(users(:drica))
    get edit_user_credential_path(credential)
    assert_response :not_found
  end

  test "update changes the credential" do
    credential = create_credential
    without_authorized_keys_file do
      patch user_credential_path(credential), params: { user_credential: { title: "desktop" } }
    end
    assert_redirected_to user_credentials_path
    assert_response :see_other
    assert_equal "desktop", credential.reload.title
    assert_equal "User credential was successfully updated.", flash[:notice]
  end

  test "update with invalid params renders the form with 422" do
    credential = create_credential
    patch user_credential_path(credential), params: { user_credential: { key: "" } }
    assert_response :unprocessable_content
    assert_select "#error_explanation"
  end

  test "destroy removes the credential and redirects to the list" do
    credential = create_credential
    assert_difference -> { UserCredential.count }, -1 do
      without_authorized_keys_file { delete user_credential_path(credential) }
    end
    assert_redirected_to user_credentials_path
    assert_response :see_other
  end

  test "destroy does not find credentials of other users" do
    credential = create_credential(users(:drica))
    assert_no_difference -> { UserCredential.count } do
      delete user_credential_path(credential)
    end
    assert_response :not_found
  end
end
